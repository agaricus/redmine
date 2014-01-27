class EasyUserTimeCalendarException < ActiveRecord::Base

  belongs_to :calendar, :class_name => "EasyUserTimeCalendar", :foreign_key => 'calendar_id'

  validates_numericality_of :working_hours, :allow_nil => false, :message => :invalid, :greater_than_or_equal_to => 0.0, :less_than_or_equal_to => 24.0
  validates_presence_of :calendar_id, :exception_date

  def self.human_attribute_name(attribute, *args)
    l("activerecord.attributes.easy_user_time_calendar_exception.#{attribute}")
  end

end