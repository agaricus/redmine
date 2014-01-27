class CreateEasyPageZones < ActiveRecord::Migration

  def self.up
    create_table :easy_page_zones do |t|
      t.column :zone_name, :string, { :null => false }
    end
    
    EasyPageZone.create :zone_name => "top-left"
    EasyPageZone.create :zone_name => "top-middle"
    EasyPageZone.create :zone_name => "top-right"
    EasyPageZone.create :zone_name => "middle-left"
    EasyPageZone.create :zone_name => "middle-middle"
    EasyPageZone.create :zone_name => "middle-right"
    EasyPageZone.create :zone_name => "bottom-left"
    EasyPageZone.create :zone_name => "bottom-middle"
    EasyPageZone.create :zone_name => "bottom-right"
    EasyPageZone.create :zone_name => "right-sidebar"
  end

  def self.down
   drop_table :easy_page_zones
  end
end