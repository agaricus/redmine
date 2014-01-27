module EasyPatch
  module MailerPatch

    def self.included(base)
      base.extend(ClassMethods)
      base.send(:include, InstanceMethods)

      base.class_eval do

        helper :easy_journal
        helper :entity_attribute

        alias_method_chain :issue_add, :easy_extensions
        alias_method_chain :issue_edit, :easy_extensions
        alias_method_chain :news_added, :easy_extensions
        alias_method_chain :document_added, :easy_extensions

        class << self

          def send_mail_issue_add(issue)
            return if issue.project && (issue.project.easy_is_easy_template? || issue.project.is_planned)

            if EasySetting.value('just_one_issue_mail')
              issue_add(issue, issue.get_notified_mails_for_mail(:all), :all).deliver
            else
              users_to_notify = issue.get_notified_users_for_mail_grouped_by_lang(:assigned_to)
              send_mail_issue_add_to_users_by_lang(issue, users_to_notify[:to], :assigned_to)
              send_mail_issue_add_to_users_by_lang(issue, users_to_notify[:cc], :assigned_to)

              users_to_notify = issue.get_notified_users_for_mail_grouped_by_lang(:except_assigned_to)
              send_mail_issue_add_to_users_by_lang(issue, users_to_notify[:to], :except_assigned_to)
              send_mail_issue_add_to_users_by_lang(issue, users_to_notify[:cc], :except_assigned_to)
            end
          end

          def send_mail_issue_edit(journal)
            issue = journal.journalized.reload
            return if issue.project && (issue.project.easy_is_easy_template? || issue.project.is_planned)

            if EasySetting.value('just_one_issue_mail')
              issue_edit(journal, issue.get_notified_mails_for_mail(:all, journal), :all).deliver
            else
              users_to_notify = issue.get_notified_users_for_mail_grouped_by_lang(:assigned_to, journal)
              send_mail_issue_edit_to_users_by_lang(journal, users_to_notify[:to], :assigned_to)
              send_mail_issue_edit_to_users_by_lang(journal, users_to_notify[:cc], :assigned_to)

              users_to_notify = issue.get_notified_users_for_mail_grouped_by_lang(:except_assigned_to, journal)
              send_mail_issue_edit_to_users_by_lang(journal, users_to_notify[:to], :except_assigned_to)
              send_mail_issue_edit_to_users_by_lang(journal, users_to_notify[:cc], :except_assigned_to)
            end
          end

          def send_mail_issue_add_to_users_by_lang(issue, users_to_notify_by_lang, type)
            users_to_notify_by_lang.each do |lang, mails|
              I18n.with_locale(lang.to_sym) do
                issue_add(issue, {:to => mails, :cc => []}, type, lang).deliver
              end
            end
          end

          def send_mail_issue_edit_to_users_by_lang(journal, users_to_notify_by_lang, type)
            users_to_notify_by_lang.each do |lang, mails|
              I18n.with_locale(lang.to_sym) do
                issue_edit(journal, {:to => mails, :cc => []}, type, lang).deliver
              end
            end
          end

        end

        # ==== Attributes
        #
        # * +journal+
        # * +type+ - Possible values: :all (sends mail to every recipient), :assigned_to (sends mail only to assignee),
        # :except_assigned_to (sends mail to every recipient except assignee)
        def get_recipients_for_issue(issue, type = :all, journal = nil)
          if issue.assigned_to
            assigned_notified_mails = (issue.assigned_to.is_a?(Group) ? issue.assigned_to.users : [issue.assigned_to]).select{|u| u.active? && u.notify_about?(issue)}.collect(&:mail)
          else
            assigned_notified_mails = []
          end
          if journal
            assigned_notified_mails = (assigned_notified_mails & journal.recipients)
          end

          case type
          when :all
            issue_recipients = journal.nil? ? issue.recipients : journal.recipients
            issue_watchers = (issue.watcher_recipients - issue_recipients)
          when :assigned_to
            issue_recipients = assigned_notified_mails
            issue_watchers = []
          when :except_assigned_to
            issue_recipients = []
            if journal
              issue_watchers = (journal.recipients | journal.watcher_recipients) - assigned_notified_mails
            else
              issue_watchers = (issue.recipients | issue.watcher_recipients) - assigned_notified_mails
            end
          end

          {:to => issue_recipients, :cc => issue_watchers}
        end

        def get_mail_subject_for_issue_add(issue, type = :all)
          if EasySetting.value('just_one_issue_mail')
            "[#{issue.project.name} - #{issue.tracker.name} ##{issue.id}] (#{issue.status.name}) #{issue.subject}"
          else
            l((type == :assigned_to ? :'mail.subject.my_issue_add' : :'mail.subject.issue_add'),
              :issuestatus => issue.status.name,
              :issuesubject => (EasySetting.value('show_issue_id', issue.project) ? "##{issue.id} - #{issue.subject}" : issue.subject),
              :projectname => issue.project.family_name(:separator => ' > '))
          end
        end

        def get_mail_subject_for_issue_edit(issue, journal, type = :all)
          if EasySetting.value('just_one_issue_mail')
            s = "[#{issue.project.name} - #{issue.tracker.name} ##{issue.id}] "
            s << "(#{issue.status.name}) " if journal.new_value_for('status_id')
            s << issue.subject
            s
          else
            l((type == :assigned_to ? :'mail.subject.my_issue_edit' : :'mail.subject.issue_edit'),
              :issuestatus => issue.status.name,
              :issuesubject => (EasySetting.value('show_issue_id', issue.project) ? "##{issue.id} - #{issue.subject}" : issue.subject),
              :projectname => issue.project.family_name(:separator => ' > '))
          end
        end

        def get_mail_subject_for_news_add(news)
          l(:'mail.subject.news_added', :newstitle => news.title, :projectname => news.project.family_name(:separator => ' > '))
        end

        def get_mail_subject_for_document_add(document)
          l(:'mail.subject.document_added', :documenttitle => document.title, :projectname => document.project.family_name(:separator => ' > '))
        end
      end
    end

    module ClassMethods

    end

    module InstanceMethods

      # ==== Attributes
      #
      # * +journal+
      # * +type+ - Possible values: :all (sends mail to every recipient), :assigned_to (sends mail only to assignee),
      # :except_assigned_to (sends mail to every recipient except assignee)
      def issue_add_with_easy_extensions(issue, issue_recipients = {}, type = :all, lang = nil)
        return if issue.project && (issue.project.easy_is_easy_template? || issue.project.status == Project::STATUS_PLANNED)
        set_language_if_valid(lang) if lang
        redmine_headers 'Project' => issue.project.id,
          'Issue-Id' => issue.id,
          'Issue-Author' => issue.author.login
        redmine_headers 'Issue-Assignee' => issue.assigned_to.login if issue.assigned_to
        message_id issue
        references issue

        @author = issue.author # redmine inner logic in "mail" function
        @issue = issue
        @issue_url = url_for(:controller => 'issues', :action => 'show', :id => issue)
        @users = issue_recipients[:to] + issue_recipients[:cc]

        issue_subject = get_mail_subject_for_issue_add(issue, type)

        mail :to => issue_recipients[:to],
          :cc => issue_recipients[:cc],
          :subject => issue_subject
      end

      # ==== Attributes
      #
      # * +journal+
      # * +type+ - Possible values: :all (sends mail to every recipient), :assigned_to (sends mail only to assignee),
      # :except_assigned_to (sends mail to every recipient except assignee)
      def issue_edit_with_easy_extensions(journal, issue_recipients = {}, type = :all, lang = nil)
        issue = journal.journalized
        return if issue.project && (issue.project.easy_is_easy_template? || issue.project.status == Project::STATUS_PLANNED)
        set_language_if_valid(lang) if lang
        redmine_headers 'Project' => issue.project.id,
          'Issue-Id' => issue.id,
          'Issue-Author' => issue.author.login
        redmine_headers 'Issue-Assignee' => issue.assigned_to.login if issue.assigned_to
        message_id journal
        references issue

        @author = journal.user # redmine inner logic in "mail" function
        @issue = issue
        @journal = journal
        @issue_url = url_for(:controller => 'issues', :action => 'show', :id => issue, :anchor => "change-#{journal.id}")
        @users = issue_recipients[:to] + issue_recipients[:cc]

        issue_subject = get_mail_subject_for_issue_edit(issue, journal, type)

        mail :to => issue_recipients[:to],
          :cc => issue_recipients[:cc],
          :subject => issue_subject
      end

      def news_added_with_easy_extensions(news)
        redmine_headers 'Project' => news.project.identifier
        message_id news
        references news

        @author = news.author # redmine inner logic in "mail" function
        @news = news
        @news_url = url_for(:controller => 'news', :action => 'show', :id => news)

        mail :to => news.recipients,
          :subject => get_mail_subject_for_news_add(news)
      end

      def document_added_with_easy_extensions(document)
        redmine_headers 'Project' => document.project.identifier

        @author = User.current # redmine inner logic in "mail" function
        @document = document
        @document_url = url_for(:controller => 'documents', :action => 'show', :id => document)

        mail :to => document.recipients,
          :subject => get_mail_subject_for_document_add(document)
      end

    end
  end
end
EasyExtensions::PatchManager.register_model_patch 'Mailer', 'EasyPatch::MailerPatch'
