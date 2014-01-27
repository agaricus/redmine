require 'net/pop'

module EasyExtensions
  module POP3

    class << self

      def test_connection(pop_options={})
        host = pop_options[:host] || '127.0.0.1'
        port = pop_options[:port] || '110'
        apop = (pop_options[:apop].to_s == '1')

        pop = Net::POP3.APOP(apop).new(host,port)

        pop.start(pop_options[:username], pop_options[:password]) do |pop_session|
        end

        return true
      end

      def check(pop_options={}, options={})
        host = pop_options[:host] || '127.0.0.1'
        port = pop_options[:port] || '110'
        apop = (pop_options[:apop].to_s == '1')
        delete_unprocessed = (pop_options[:delete_unprocessed].to_s == '1')
        easy_rake_task = options[:easy_rake_task]

        all_ok = false

        pop = Net::POP3.APOP(apop).new(host,port)
        logger.debug "#{Time.now} Connecting to #{host} - #{pop_options[:username]}..." if logger && logger.debug?

        pop.start(pop_options[:username], pop_options[:password]) do |pop_session|
          all_ok = true

          if pop_session.mails.empty?
            logger.debug "#{Time.now} No email to process" if logger && logger.debug?
          else
            logger.debug "#{Time.now} #{pop_session.mails.size} email(s) to process..." if logger && logger.debug?
            pop_session.each_mail do |msg|
              message = msg.pop
              message_id = (message =~ /^Message-I[dD]: (.*)/ ? $1 : '').strip
              att = nil

              if easy_rake_task
                if easy_rake_task.current_easy_rake_task_info
                  easy_rake_task_info_detail = easy_rake_task.current_easy_rake_task_info.easy_rake_task_info_details.build
                  easy_rake_task_info_detail.type = 'EasyRakeTaskInfoDetailReceiveMail'
                  easy_rake_task_info_detail.save

                  options[:easy_rake_task_info_detail] = easy_rake_task_info_detail
                end

                message_subject = (message =~ /^Subject: (.*)/ ? $1 : '').strip
                message_disk_filename = Attachment.disk_filename(Attachment.sanitize_filename(message_subject + '.eml'))
                message_disk_filename = message_disk_filename.split('_')
                att = Attachment.where(:container_type => 'EasyRakeTask').where(["#{Attachment.table_name}.disk_filename LIKE ?", "%#{message_disk_filename.last}"]).first
                att ||= EasyUtils::FileUtils.save_and_attach_email_message(message, message_id, easy_rake_task, message_subject, User.current)
              end

              status = EasyRakeTaskInfoDetailReceiveMail::STATUS_UNKNOWN
              status_detail = nil

              begin
                mail_processed = MailHandler.receive(message, options)
              rescue Exception => e
                ex_msg = e.message.to_s
                status_detail = ex_msg.encode(:invalid => :replace, :replace => '') if ex_msg.respond_to?(:encode)
              end

              if mail_processed
                msg.delete
                logger.debug "#{Time.now} Message #{message_id} processed and deleted from the server" if logger && logger.debug?

                status = EasyRakeTaskInfoDetailReceiveMail::STATUS_PROCESSED_AND_DELETED
              else
                if delete_unprocessed
                  msg.delete
                  logger.debug "#{Time.now} Message #{message_id} NOT processed and deleted from the server" if logger && logger.debug?

                  status = EasyRakeTaskInfoDetailReceiveMail::STATUS_NOT_PROCESSED_AND_DELETED
                else
                  logger.debug "#{Time.now} Message #{message_id} NOT processed and left on the server" if logger && logger.debug?
                  all_ok = false
                  status = EasyRakeTaskInfoDetailReceiveMail::STATUS_NOT_PROCESSED_AND_LEFT_ON_SERVER
                end
              end

              if easy_rake_task_info_detail
                easy_rake_task_info_detail.status = status
                easy_rake_task_info_detail.reference = att
                easy_rake_task_info_detail.detail = status_detail
                easy_rake_task_info_detail.save
              end

            end
          end
        end

        all_ok
      end

      private

      def logger
        @email_logger ||= Logger.new(File.join(Rails.root, 'log', 'pop3.log'), 'weekly')
      end
    end

  end
end
