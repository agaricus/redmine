class CreateEasyPageTemplateModules < ActiveRecord::Migration

  def self.up
    create_table :easy_page_template_modules, {:id => false} do |t|
      t.belongs_to :easy_page_templates, { :null => false }
      t.belongs_to :easy_page_available_zones, { :null => false }
      t.belongs_to :easy_page_available_modules, { :null => false }
      t.string :uuid, { :null => false }
      t.references :entity, { :null => true }
      t.integer :position, { :null => true, :default => 1 }
      t.text :settings, { :null => true }
      t.references :tab
    end

    add_index :easy_page_template_modules, [:easy_page_templates_id, :easy_page_available_zones_id], :name => 'idx_easy_page_template_modules_1'
    add_index :easy_page_template_modules, [:uuid], :unique => true, :name => 'idx_easy_page_template_modules_2'
  end

  def self.down
    drop_table :easy_page_template_modules
  end
end
