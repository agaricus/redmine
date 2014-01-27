class AddEasyPageModuleType < ActiveRecord::Migration
  def self.up

    add_column :easy_page_modules, :type, :string, :null => true

    EasyPageModule.reset_column_information

    EasyPageModule.connection.select_all("SELECT id, module_name FROM #{EasyPageModule.table_name}").each do |row|
      new_name = ('epm_' + row['module_name']).camelize
      EasyPageModule.update_all("type = '#{new_name}'", "id = #{row['id']}")
    end

    remove_column :easy_page_modules, :module_name
    remove_column :easy_page_modules, :category_name
    remove_column :easy_page_modules, :view_path
    remove_column :easy_page_modules, :edit_path
    remove_column :easy_page_modules, :default_settings
    remove_column :easy_page_modules, :permissions
    
  end

  def self.down

  end
  
end
