class DeleteAttachmentsFromEasyRakeTaskInfoDetails < ActiveRecord::Migration
  def self.up
    Attachment.where(:container_type => 'EasyRakeTaskInfoDetail').destroy_all
  end

  def self.down
  end

end