class AddTableEasyPageTemplateTabs < ActiveRecord::Migration
  def self.up
    create_table :easy_page_template_tabs do |t|
      t.column :page_template_id, :integer, { :null => false }
      t.column :position, :integer, { :null => true, :default => 1 }
      t.column :name, :string, { :null => false }
      t.column :entity_id, :integer, { :null => true }
    end
  end

  def self.down
    drop_table :easy_page_template_tabs
  end
end
