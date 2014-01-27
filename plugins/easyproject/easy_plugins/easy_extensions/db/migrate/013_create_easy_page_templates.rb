class CreateEasyPageTemplates < ActiveRecord::Migration

  def self.up
    create_table :easy_page_templates do |t|
      t.belongs_to :easy_pages
      t.column :template_name, :string, { :null => false }
      t.column :description, :string, { :null => true, :length => 255 }
      t.column :is_default, :boolean, :default => false, :null => false
      t.column :position, :integer, { :null => true, :default => 1 }
     end
    
  end

  def self.down
    drop_table :easy_page_templates
  end
end