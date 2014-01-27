class EasyPageAvailableZone < ActiveRecord::Base
  self.table_name = 'easy_page_available_zones'

  belongs_to :page_definition, :class_name => "EasyPage", :foreign_key => 'easy_pages_id'
  belongs_to :zone_definition, :class_name => "EasyPageZone", :foreign_key => 'easy_page_zones_id'
  has_many :all_modules, :class_name => "EasyPageZoneModule", :foreign_key => 'easy_page_available_zones_id', :dependent => :destroy

  acts_as_list :scope => :easy_pages_id

  validates_presence_of :easy_pages_id
  validates_presence_of :easy_page_zones_id

  def self.ensure_easy_page_available_zone(easy_page, easy_page_zone)
    return false unless easy_page.is_a?(EasyPage) || easy_page_zone.is_a?(EasyPageZone)
    saved_zone = EasyPageAvailableZone.find_by_easy_pages_id_and_easy_page_zones_id(easy_page.id, easy_page_zone.id)
    EasyPageAvailableZone.create(:easy_pages_id => easy_page.id, :easy_page_zones_id => easy_page_zone.id) if (saved_zone.nil?)
  end

  def self.delete_easy_page_available_zone(easy_page, easy_page_zone)
    saved_zone = EasyPageAvailableZone.find_by_easy_pages_id_and_easy_page_zones_id(easy_page.id, easy_page_zone.id)
    saved_zone.delete unless (saved_zone.nil?)
  end
    
end


