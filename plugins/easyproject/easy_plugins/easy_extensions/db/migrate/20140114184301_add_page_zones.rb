class AddPageZones < ActiveRecord::Migration
  def up
    EasyPageZone.create :zone_name => "middle2-left"
    EasyPageZone.create :zone_name => "middle2-middle"
    EasyPageZone.create :zone_name => "middle2-right"
    EasyPageZone.create :zone_name => "middle3-left"
    EasyPageZone.create :zone_name => "middle3-middle"
    EasyPageZone.create :zone_name => "middle3-right"
  end

  def down
  end
end
