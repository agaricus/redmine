class CreateEasyPublishingSettings < ActiveRecord::Migration
  def self.up
    create_table :easy_publishing_settings do |t|
      t.column :controller, :string, {:null => false, :length => 255, :default => ''}
      t.column :action, :string, {:null => false, :length => 255, :default => ''}
      t.column :url, :string, {:null => false, :length => 600, :default => ''}
      t.column :easy_publishing_module_id, :integer, {:null => false}
      t.column :body, :text, {:null => true, :default => nil}
    end
  end
  
  def self.down
    drop_table :easy_publishing_settings
  end
end