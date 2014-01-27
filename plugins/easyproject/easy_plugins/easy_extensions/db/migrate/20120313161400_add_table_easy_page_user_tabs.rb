class AddTableEasyPageUserTabs < ActiveRecord::Migration
  def self.up
    create_table :easy_page_user_tabs do |t|
      t.column :page_id, :integer, { :null => false }
      t.column :user_id, :integer, { :null => false }
      t.column :position, :integer, { :null => true, :default => 1 }
      t.column :name, :string, { :null => false }
    end
  end

  def self.down
    drop_table :easy_page_user_tabs
  end
end
