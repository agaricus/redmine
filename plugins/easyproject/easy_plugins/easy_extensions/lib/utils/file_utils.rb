module EasyUtils
  class FileUtils

    def self.save_email_message_to_file(message, message_id, close_file = false)
      tmp_file = nil

      begin
        if RUBY_VERSION >= '1.9'
          tmp_file = Tempfile.new(Attachment.disk_filename("#{message_id.to_s}.eml"), Rails.root.join('tmp').to_s, :encoding => 'ascii-8bit')
        else
          tmp_file = Tempfile.new(Attachment.disk_filename("#{message_id.to_s}.eml"), Rails.root.join('tmp').to_s)
        end

        tmp_file.write(message.to_s.gsub(/\r\n/, "\n"))
        tmp_file.rewind
        tmp_file.close if close_file
      rescue Exception => e
        Rails.logger.error "EasyUtils::FileUtils.save_email_message_to_file -> cannot create tmp_file #{e.message}"
      end

      return tmp_file
    end

    def self.save_email_to_file(email, close_file = false)
      save_email_message_to_file(email, email.message_id, close_file)
    end

    def self.attach_email_to_entity(tmp_file, entity, attachment_file_name, author)
      author ||= User.current
      attachment_file_name = 'Unknown subject' if attachment_file_name.blank?
      a = nil
      if tmp_file
        a = Attachment.new(:file => tmp_file, :author => author)
        a.container = entity
        a.content_type = 'application/octet-stream'
        a.filename = "#{attachment_file_name.to_s}.eml"
        a.save
        tmp_file.close
      end
      return a
    end

    def self.save_and_attach_email_message(message, message_id, entity, attachment_file_name, author)
      tmp_file = save_email_message_to_file(message, message_id, false)
      attach_email_to_entity(tmp_file, entity, attachment_file_name, author)
    end

    def self.save_and_attach_email(email, entity, attachment_file_name, author)
      tmp_file = save_email_to_file(email, false)
      attach_email_to_entity(tmp_file, entity, attachment_file_name, author)
    end

  end
end
