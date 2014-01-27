class AddAttachmentsCategory < ActiveRecord::Migration
  def self.up
    add_column :attachments, :category, :string, :limit => 255, :null => true
  end

  def self.down
    remove_column :attachments, :category
  end

end
