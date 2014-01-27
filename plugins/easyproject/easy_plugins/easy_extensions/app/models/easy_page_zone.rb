class EasyPageZone < ActiveRecord::Base
  self.table_name = 'easy_page_zones'

  has_many :available_in_pages, :class_name => "EasyPageAvailableZone", :foreign_key => 'easy_page_zones_id'

  validates_length_of :zone_name, :in => 1..50, :allow_nil => false

  before_save :change_zone_name

  @@easy_page_zones = {}

  EasyPageZone.all.each do |zone|
    src = <<-end_src
      def self.zone_#{zone.zone_name.underscore}
        @@easy_page_zones[#{zone.id}] ||= EasyPageZone.find(#{zone.id})
      end
    end_src
    class_eval src, __FILE__, __LINE__
  end if EasyPageZone.table_exists?

  def translated_name
    l("easy_pages.zones.#{zone_name.underscore}")
  end

  def translated_description
    l("easy_pages.zones_description.#{zone_name.underscore}")
  end

  private

  def change_zone_name
    self.zone_name = self.zone_name.gsub(/[ ]/, '-').dasherize unless self.zone_name.nil?
  end

end

