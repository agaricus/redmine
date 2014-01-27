class AttachmentsVersioned < ActiveRecord::Migration
  def self.up
    Attachment.create_versioned_table
  end

  def self.down
    Attachment.drop_versioned_table
  end
end
