class CreateEasyPageZoneModules < ActiveRecord::Migration

  def self.up
    create_table :easy_page_zone_modules, {:id => false} do |t|
      t.belongs_to :easy_pages, { :null => false }
      t.belongs_to :easy_page_available_zones, { :null => false }
      t.belongs_to :easy_page_available_modules, { :null => false }
      t.references :user, { :null => true }
      t.string :uuid, { :null => false }
      t.references :entity, { :null => true }
      t.integer :position, { :null => true, :default => 1 }
      t.text :settings, { :null => true }
      t.references :tab




    end

    add_index :easy_page_zone_modules, [:easy_pages_id, :easy_page_available_zones_id, :user_id], :name => 'idx_easy_page_zone_modules_1'
    add_index :easy_page_zone_modules, [:uuid], :unique => true, :name => 'idx_easy_page_zone_modules_2'
  end

  def self.down
    drop_table :easy_page_zone_modules
  end
end
