class AddEasyPageModulesPermission < ActiveRecord::Migration
  def self.up
    add_column :easy_page_modules, :permissions, :text, { :null => true }

    EasyPageModule.reset_column_information
  end

  def self.down
  end
end
