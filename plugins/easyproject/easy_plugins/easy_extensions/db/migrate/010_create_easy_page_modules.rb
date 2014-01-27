class CreateEasyPageModules < ActiveRecord::Migration

  def self.up
    create_table :easy_page_modules do |t|
      t.column :module_name, :string, { :null => false }
      t.column :category_name, :string, { :null => false }
      t.column :view_path, :string, { :null => true, :length => 255 }
      t.column :edit_path, :string, { :null => true, :length => 255 }
      t.column :default_settings, :text, { :null => true }
    end
  end

  def self.down
   drop_table :easy_page_modules
  end
end