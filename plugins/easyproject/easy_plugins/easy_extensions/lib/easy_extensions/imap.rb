require 'net/imap'

module EasyExtensions
  module IMAP

    class << self

      def test_connection(imap_options={})
        host = imap_options[:host] || '127.0.0.1'
        port = imap_options[:port] || '143'
        ssl = !imap_options[:ssl].nil?
        folder = imap_options[:folder] || 'INBOX'

        imap = Net::IMAP.new(host, port, ssl)
        imap.login(imap_options[:username], imap_options[:password]) unless imap_options[:username].nil?
        imap.select(folder)
        imap.disconnect

        return true
      end

      def check(imap_options={}, options={})
        host = imap_options[:host] || '127.0.0.1'
        port = imap_options[:port] || '143'
        ssl = !imap_options[:ssl].nil?
        folder = imap_options[:folder] || 'INBOX'
        easy_rake_task = options[:easy_rake_task]

        all_ok = false

        imap = Net::IMAP.new(host, port, ssl)
        imap.login(imap_options[:username], imap_options[:password]) unless imap_options[:username].nil?
        imap.select(folder)

        all_ok = true

        logger.debug "#{Time.now} Connecting to #{host} - #{imap_options[:username]}..." if logger && logger.debug?

        imap.uid_search(['NOT', 'SEEN']).each do |uid|
          msg = imap.uid_fetch(uid,'RFC822')[0].attr['RFC822']
          att = nil
          logger.debug "#{Time.now} Receiving message #{uid}" if logger && logger.debug?

          if easy_rake_task
            if easy_rake_task.current_easy_rake_task_info
              easy_rake_task_info_detail = easy_rake_task.current_easy_rake_task_info.easy_rake_task_info_details.build
              easy_rake_task_info_detail.type = 'EasyRakeTaskInfoDetailReceiveMail'
              easy_rake_task_info_detail.save

              options[:easy_rake_task_info_detail] = easy_rake_task_info_detail
            end

            message_subject = (msg =~ /^Subject: (.*)/ ? $1 : '').strip
            message_disk_filename = Attachment.disk_filename(Attachment.sanitize_filename(message_subject + '.eml'))
            message_disk_filename = message_disk_filename.split('_')
            att = Attachment.where(:container_type => 'EasyRakeTask').where(["#{Attachment.table_name}.disk_filename LIKE ?", "%#{message_disk_filename.last}"]).first
            att ||= EasyUtils::FileUtils.save_and_attach_email_message(msg, uid, easy_rake_task, message_subject, User.current)
          end

          status = EasyRakeTaskInfoDetailReceiveMail::STATUS_UNKNOWN
          status_detail = nil

          begin
            mail_processed = MailHandler.receive(msg, options)
          rescue Exception => e
            ex_msg = e.message.to_s
            status_detail = ex_msg.encode(:invalid => :replace, :replace => '') if ex_msg.respond_to?(:encode)
          end

          if mail_processed
            logger.debug "#{Time.now} Message #{uid} successfully received" if logger && logger.debug?
            if imap_options[:move_on_success]
              encoded_option = imap_options[:move_on_success]
              imap.uid_copy(uid, encoded_option.force_encoding('ASCII-8BIT'))
            end
            imap.uid_store(uid, "+FLAGS", [:Seen, :Deleted])

            status = EasyRakeTaskInfoDetailReceiveMail::STATUS_RECEIVED
          else
            logger.debug "#{Time.now} Message #{uid} can not be processed" if logger && logger.debug?
            all_ok = false
            imap.uid_store(uid, "+FLAGS", [:Seen])
            if imap_options[:move_on_failure]
              encoded_option = imap_options[:move_on_failure]
              imap.uid_copy(uid, encoded_option.force_encoding('ASCII-8BIT'))
              imap.uid_store(uid, "+FLAGS", [:Deleted])
            end

            status = EasyRakeTaskInfoDetailReceiveMail::STATUS_CANNOT_BE_PROCESSED
          end

          if easy_rake_task_info_detail
            easy_rake_task_info_detail.status = status
            easy_rake_task_info_detail.reference = att
            easy_rake_task_info_detail.detail = status_detail
            easy_rake_task_info_detail.save
          end

        end
        imap.expunge
        imap.logout
        imap.disconnect

        all_ok
      end

      private

      def logger
        @email_logger ||= Logger.new(File.join(Rails.root, 'log', 'imap.log'), 'weekly')
      end

    end
  end
end
