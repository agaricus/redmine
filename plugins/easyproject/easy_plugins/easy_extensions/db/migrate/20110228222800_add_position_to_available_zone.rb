class AddPositionToAvailableZone < ActiveRecord::Migration
  def self.up
    add_column :easy_page_available_zones, :position, :integer, { :null => true, :default => 1 }
  end

  def self.down
    remove_column :easy_page_available_zones, :position
  end
end
