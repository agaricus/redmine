class EasyUserTimeCalendarHoliday < ActiveRecord::Base

  default_scope :order => "#{EasyUserTimeCalendarHoliday.table_name}.is_repeating DESC, #{EasyUserTimeCalendarHoliday.table_name}.holiday_date ASC"

  belongs_to :calendar, :class_name => "EasyUserTimeCalendar", :foreign_key => 'calendar_id'

  validates_length_of :name, :in => 0..255, :allow_nil => true
  validates_presence_of :calendar_id, :holiday_date

  def self.human_attribute_name(attribute, *args)
    l("activerecord.attributes.easy_user_working_time_calendar_holiday.#{attribute}")
  end

end