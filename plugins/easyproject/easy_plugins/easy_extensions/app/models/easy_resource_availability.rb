class EasyResourceAvailability < ActiveRecord::Base

  belongs_to :author, :class_name => 'User', :foreign_key => 'author_id'

  validates_presence_of :date

  scope :for_timeline, lambda {|uuid, start_date, end_date| {
      :conditions => ["#{EasyResourceAvailability.table_name}.easy_page_zone_module_uuid = ? AND #{EasyResourceAvailability.table_name}.date BETWEEN ? AND ?", uuid, start_date, end_date],
      :order => "#{EasyResourceAvailability.table_name}.date, #{EasyResourceAvailability.table_name}.hour"}}

  def self.timeline(uuid, start_date, end_date)
    availabilities = EasyResourceAvailability.for_timeline(uuid, start_date, end_date).group_by(&:date)
    timeline = {}
    start_date.upto(end_date) do |d|
      if availabilities.has_key?(d)
        timeline[d] = availabilities[d].inject({}){|memo, a| memo[a.hour] = a;memo}
      else
        timeline[d] = {}
      end
    end
    timeline
  end

    def self.set_availability(uuid, date, hour=nil, available=false, description=nil, day_start_time=8, day_end_time=18)
    if hour.blank?
      EasyResourceAvailability.where(:easy_page_zone_module_uuid => uuid, :date => date).destroy_all
      unless available
        day_start_time.upto(day_end_time) do |i|
          self.create!(:easy_page_zone_module_uuid => uuid, :date => date, :hour => i, :author => User.current, :description => description)
        end
      end
    else
      EasyResourceAvailability.where(:easy_page_zone_module_uuid => uuid, :date => date, :hour => hour).destroy_all
      unless available
        self.create!(:easy_page_zone_module_uuid => uuid, :date => date, :hour => hour, :author => User.current, :description => description)
      end
    end
  end

end
