class MigrateFirstAttachmentsVersion < ActiveRecord::Migration
  def self.up
    say_with_time 'Please wait. Creating the first version of all attachments. This will take a moment...' do
      Attachment.all.each(&:save)
    end
  end

  def self.down
  end
end
