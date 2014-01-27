class ChangeEasyPageZoneModulesIndex < ActiveRecord::Migration
  def self.up
    remove_index :easy_page_zone_modules, :name => 'idx_easy_page_zone_modules_1'
    add_index :easy_page_zone_modules, [:easy_pages_id, :easy_page_available_zones_id, :user_id, :entity_id, :tab], :name => 'idx_easy_page_zone_modules_1'
  end

  def self.down
  end
end
