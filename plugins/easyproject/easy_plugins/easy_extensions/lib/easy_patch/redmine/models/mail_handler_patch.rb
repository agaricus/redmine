require 'utils/file_utils'

module EasyPatch
  module MailHandlerPatch

    def self.included(base)
      base.extend(ClassMethods)
      base.send(:include, InstanceMethods)

      base.class_eval do
        cattr_accessor :handler_options

        alias_method_chain :add_attachments, :easy_extensions
        alias_method_chain :receive, :easy_extensions
        alias_method_chain :receive_issue, :easy_extensions
        alias_method_chain :receive_issue_reply, :easy_extensions
        alias_method_chain :extract_keyword!, :easy_extensions
        alias_method_chain :get_keyword, :easy_extensions
        alias_method_chain :plain_text_body, :easy_extensions
        alias_method_chain :cleanup_body, :easy_extensions

        class << self
          alias_method_chain :receive, :easy_extensions
        end

        def save_email_as_eml(issue)
          EasyUtils::FileUtils.save_and_attach_email(email, issue, issue.subject.to_s, User.current)
        end

        def stripped_plain_text_body
          return @stripped_plain_text_body unless @stripped_plain_text_body.nil?

          part = email.text_part || email.html_part || email
          @stripped_plain_text_body = Redmine::CodesetUtil.to_utf8(part.body.decoded, part.charset)

          # strip html tags and remove doctype directive
          @stripped_plain_text_body = strip_tags(@stripped_plain_text_body.strip)
          @stripped_plain_text_body.sub! %r{^<!DOCTYPE .*$}, ''
          @stripped_plain_text_body
        end

        def log_info_msg(err_msg)
          logger.info(err_msg) if logger
          self.class.handler_options[:easy_rake_task_info_detail].update_column(:detail, err_msg) if self.class.handler_options[:easy_rake_task_info_detail]
        end

        def log_error_msg(err_msg)
          logger.error(err_msg) if logger
          self.class.handler_options[:easy_rake_task_info_detail].update_column(:detail, err_msg) if self.class.handler_options[:easy_rake_task_info_detail]
        end

      end
    end

    module ClassMethods
      def receive_with_easy_extensions(email, options={})
        charset = email.dup.force_encoding('binary').match(/Content-Type.*text\/.*\n?.*charset=["'\s]*([\w\-]*)["'\/\n]?/)
        charset = charset && charset[1].strip
        if charset.present?
          # begin
          unless charset =~ /ascii/
            email.force_encoding(charset.gsub(/3d/i, ''))
            email.encode!('UTF-8')
          end
          # rescue Exception => e
          #   Rails.logger.error(e.to_s)
          #   email.force_encoding('ASCII-8BIT') if email.respond_to?(:force_encoding)
          # end
        else
          email.force_encoding('ASCII-8BIT') if email.respond_to?(:force_encoding)
        end
        receive_without_easy_extensions(email, options)
      end
    end

    module InstanceMethods

      def add_attachments_with_easy_extensions(obj)
        if email.attachments && email.attachments.any?
          email.attachments.each do |attachment|
            next unless accept_attachment?(attachment)
            if attachment.header.to_s.match(/Content-Disposition: attachment;/)
              attachment_or_nothing = obj.get_existing_version(attachment.filename, {})
              if attachment_or_nothing
                attachment_or_nothing.update_attributes(
                  :file => attachment.decoded,
                  :container => obj,
                  :author => user)
                obj.after_new_version_create_journal(attachment_or_nothing)
              else
                obj.attachments.create(
                  :file => attachment.decoded,
                  :filename => attachment.filename,
                  :author => user,
                  :content_type => attachment.mime_type)
              end
            else
              logger.info "MailHandler:  ignoring signature attachment #{attachment.filename} " if logger
            end
          end
        end
      end

      # Processes incoming emails
      # Returns the created object (eg. an issue, a message) or false
      def receive_with_easy_extensions(email)
        @email = email
        sender_email = email.from.to_a.first.to_s.strip
        # Ignore emails received from the application emission address to avoid hell cycles
        if sender_email.downcase == Setting.mail_from.to_s.strip.downcase
          log_info_msg "MailHandler: ignoring email from Redmine emission address [#{sender_email}]"
          return false
        end
        # Ignore auto generated emails
        unless !self.class.handler_options.key?(:skip_ignored_emails_headers_check) || self.class.handler_options[:skip_ignored_emails_headers_check] != '1'
          self.class.ignored_emails_headers.each do |key, ignored_value|
            value = email.header[key]
            if value
              value = value.to_s.downcase
              if (ignored_value.is_a?(Regexp) && value.match(ignored_value)) || value == ignored_value
                log_info_msg "MailHandler: ignoring email with #{key}:#{value} header"
                return false
              end
            end
          end
        end
        @user = User.find_by_mail(sender_email) if sender_email.present?
        if @user && !@user.active?
          case self.class.handler_options[:unknown_user]
          when 'accept'
            @user = User.anonymous
          else
            @user = nil
          end
        end
        if @user.nil?
          # Email was submitted by an unknown user
          case self.class.handler_options[:unknown_user]
          when 'accept'
            @user = User.anonymous
          when 'create'
            @user = create_user_from_email(email)
            if @user
              logger.info "MailHandler: [#{@user.login}] account created" if logger
              add_user_to_group(self.class.handler_options[:default_group])
              unless self.class.handler_options[:no_account_notice]
                Mailer.account_information(@user, @user.password).deliver
              end
            else
              log_error_msg "MailHandler: could not create account for [#{sender_email}]"
              return false
            end
          else
            @user = User.where(:login => self.class.handler_options[:unknown_user]).first unless self.class.handler_options[:unknown_user].blank?
            if @user.nil?
              # Default behaviour, emails from unknown users are ignored
              log_info_msg "MailHandler: ignoring email from unknown user [#{sender_email}]"
              return false
            end
          end
        end
        User.current = @user
        dispatch
      end

      # Creates a new issue
      def receive_issue_with_easy_extensions
        project = target_project
        # check permission
        unless self.class.handler_options[:no_permission_check]
          raise MailHandler::UnauthorizedAction unless user.allowed_to?(:add_issues, project)
        end

        issue = Issue.new(:author => user, :project => project)
        if self.class.handler_options[:allow_override]
          issue.safe_attributes = issue_attributes_from_keywords(issue)
          issue.safe_attributes = {'custom_field_values' => custom_field_values_from_keywords(issue)}
        end
        issue.subject = cleaned_up_subject
        if issue.subject.blank?
          issue.subject = '(no subject)'
        end
        issue.description = cleaned_up_text_body

        Redmine::Hook.call_hook(:model_mail_handler_receive_issue, {:mail_handler => self, :issue => issue})

        # add To and Cc as watchers before saving so the watchers can reply to Redmine
        add_watchers(issue)

        if self.class.handler_options[:no_issue_validation]
          issue.save(:validate => false)
        else
          issue.save!
        end

        add_attachments(issue)

        save_email_as_eml(issue)

        logger.info "MailHandler: issue ##{issue.id} created by #{user}" if logger

        Redmine::Hook.call_hook(:model_mail_handler_receive_issue_created, {:mail_handler => self, :issue => issue})

        issue
      end

      def receive_issue_reply_with_easy_extensions(issue_id, from_journal=nil)
        issue = Issue.find_by_id(issue_id)
        return unless issue
        # check permission
        unless self.class.handler_options[:no_permission_check]
          unless user.allowed_to?(:add_issue_notes, issue.project) ||
              user.allowed_to?(:edit_issues, issue.project)
            raise UnauthorizedAction
          end
        end

        # ignore CLI-supplied defaults for new issues
        self.class.handler_options[:issue].clear

        journal = issue.init_journal(user)
        if from_journal && from_journal.private_notes?
          # If the received email was a reply to a private note, make the added note private
          issue.private_notes = true
        end
        issue.safe_attributes = issue_attributes_from_keywords(issue)
        issue.safe_attributes = {'custom_field_values' => custom_field_values_from_keywords(issue)}
        journal.notes = cleaned_up_text_body

        Redmine::Hook.call_hook(:model_mail_handler_receive_issue_reply, {:mail_handler => self, :issue => issue, :journal => journal})

        issue.save!
        add_attachments(issue)

        save_email_as_eml(journal.journalized)

        if logger && logger.info
          logger.info "MailHandler: issue ##{issue.id} updated by #{user}"
        end

        journal
      end

      # Destructively extracts the value for +attr+ in +text+
      # Returns nil if no matching keyword found
      def extract_keyword_with_easy_extensions!(text, attr, format=nil)
        keys = [attr.to_s.humanize]
        if attr.is_a?(Symbol)
          keys << l("field_#{attr}", :default => '', :locale =>  user.language) if user && user.language.present?
          keys << l("field_#{attr}", :default => '', :locale =>  Setting.default_language) if Setting.default_language.present?
        end
        keys.reject! {|k| k.blank?}
        keys.collect! {|k| Regexp.escape(k)}
        additional_keys = []
        keys.each do |key|
          key_without_diacritics = key.mb_chars.normalize(:kd).gsub(/[^\x00-\x7F]/n, '').to_s
          additional_keys << key_without_diacritics
          additional_keys << key_without_diacritics.downcase
          additional_keys << key_without_diacritics.upcase
          additional_keys << key.downcase
          additional_keys << key.upcase
        end
        keys << additional_keys
        keys.flatten!
        keys.uniq!
        format ||= '.+'
        regexp = /^(#{keys.join('|')})[ \t]*:[ \t]*(#{format})\s*$/i
        if m = text.match(regexp)
          keyword = m[2].strip
          text.gsub!(regexp, '')
        end
        keyword
      end

      def get_keyword_with_easy_extensions(attr, options={})
        @keywords ||= {}
        if @keywords.has_key?(attr)
          @keywords[attr]
        else
          @keywords[attr] = begin
            if (options[:override] || self.class.handler_options[:allow_override].include?(attr.to_s)) &&
                (v = extract_keyword!(stripped_plain_text_body, attr, options[:format]))
              v
            elsif !self.class.handler_options[:issue][attr].blank?
              self.class.handler_options[:issue][attr]
            end
          end
        end
      end

      def plain_text_body_with_easy_extensions
        return plain_text_body_without_easy_extensions unless Setting.text_formatting == 'HTML'
        return @plain_text_body unless @plain_text_body.nil?

        html_part, text_part = false, false
        if (text_parts = email.all_parts.select {|p| p.mime_type == 'text/plain'}).present?
          parts = text_parts
          text_part = true
        elsif (html_parts = email.all_parts.select {|p| p.mime_type == 'text/html'}).present?
          parts = html_parts
          html_part = true
        else
          parts = [email]
        end

        parts.reject! do |part|
          part.header[:content_disposition].try(:disposition_type) == 'attachment'
        end

        @plain_text_body = parts.map {|p| Redmine::CodesetUtil.to_utf8(p.body.decoded, p.charset)}.join("\r\n")

        if Setting.text_formatting == 'HTML'
          if (!html_part && text_part) || (!html_part && !text_part)
            @plain_text_body.gsub!(/\n/, '<br />')
          end
        end

        # strip html tags and remove doctype directive
        if parts.any? {|p| p.mime_type == 'text/html'}
          @plain_text_body.sub! %r{^<!DOCTYPE .*$}, ''
        end

        @plain_text_body
      end

      def cleanup_body_with_easy_extensions(body)
        cleanup_body = cleanup_body_without_easy_extensions(body)
        return cleanup_body unless Setting.text_formatting == 'HTML'

        parse_body = Nokogiri::HTML.parse(cleanup_body)
        ['head', 'meta', 'style', 'script', 'base'].each do |trash|
          parse_body.search(trash).remove
        end
        # remove blank p, that create empty lines.
        parse_body.css('p').each{|p| p.remove if p.content.strip.blank?}

        body_html = parse_body.at('body')

        return body_html.nil? ? parse_body.text : body_html.inner_html
      end

    end
  end
end
EasyExtensions::PatchManager.register_model_patch 'MailHandler', 'EasyPatch::MailHandlerPatch'
