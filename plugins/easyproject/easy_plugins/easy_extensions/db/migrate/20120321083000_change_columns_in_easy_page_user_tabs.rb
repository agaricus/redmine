class ChangeColumnsInEasyPageUserTabs < ActiveRecord::Migration
  def self.up
    change_column :easy_page_user_tabs, :user_id, :integer, { :null => true }

    add_column :easy_page_user_tabs, :entity_id, :integer, { :null => true }
  end

  def self.down
    remove_column :easy_page_user_tabs, :entity_id
  end
end
