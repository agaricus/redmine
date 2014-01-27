class CreateEasyPageAvailableZones < ActiveRecord::Migration

  def self.up
    create_table :easy_page_available_zones do |t|
      t.belongs_to :easy_pages, :easy_page_zones
    end
  end

  def self.down
    drop_table :easy_page_available_zones
  end
end