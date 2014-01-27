class ChangeDocumentTitleLength < ActiveRecord::Migration
  def self.up
    change_column :documents, :title, :string, { :null => false, :limit => 255 }
  end

  def self.down
    change_column :documents, :title, :string, { :null => false, :limit => 60 }
  end
end
