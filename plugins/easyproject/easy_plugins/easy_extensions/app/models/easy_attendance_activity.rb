class EasyAttendanceActivity < ActiveRecord::Base
  require 'ipaddr'

  has_many :easy_attendances
  has_many :time_entries, :through => :easy_attendances
  belongs_to :mapped_project, :class_name => 'Project', :foreign_key => 'mapped_project_id'
  belongs_to :mapped_time_entry_activity, :class_name => 'TimeEntryActivity', :foreign_key => 'mapped_time_entry_activity_id'

  validates :name, :presence => true

  acts_as_list
  acts_as_easy_translate

  scope :sorted, lambda { order("#{EasyAttendanceActivity.table_name}.position") }

  before_save :check_default

  def self.default
    where(:is_default => true).first
  end

  def self.ip_ranged(in_range)
    if EasyAttendance.enabled?
      plugin_settings = Setting.plugin_easy_attendances
      activity_id = plugin_settings.try(:value_at, "#{in_range ? '' : 'outside_'}ip_range_activity_id")
      if activity_id.present?
        return EasyAttendanceActivity.find(activity_id)
      end
    end
  end

  def self.for_ip(ip)
    begin
      return self.default if ip.blank?
      ip = IPAddr.new(ip) if ip.is_a?(String)

      range = EasyAttendance.office_ip_range
      return self.default if range.blank?

      self.ip_ranged(range.include?(ip))
    rescue ArgumentError
      return self.default
    end
  end

  def to_s
    return self.name
  end

  def css_classes
    s = 'easy-attendance-activity'
    s << " #{self.color_schema}"

    return s
  end

  def sum_in_days_timeentry(user, year)
    default_working_hours = user.current_working_time_calendar.default_working_hours if user.current_working_time_calendar
    default_working_hours ||= 8.0
    half_working_hours = default_working_hours / 2

    scope = self.time_entries.where(:tyear => year).where(:user_id => user.id)
    scope.all.inject(0.0) do |memo, t|
      hours = t.hours

      if hours <= 0.0
        memo
      else
        if hours <= half_working_hours
          memo += 0.5
        else
          memo += 1
        end
      end
    end
  end

  def sum_in_days_easy_attendance(user, year)
    beginning_of_year, end_of_year = DateTime.new(year).beginning_of_year, DateTime.new(year).end_of_year

    user.easy_attendances.where(:easy_attendance_activity_id => self.id).between(beginning_of_year, end_of_year).sum_spent_time(user.current_working_time_calendar, false)
  end

  private

  def check_default
    if self.is_default? && self.is_default_changed?
      EasyAttendanceActivity.update_all(:is_default => false)
    end
  end

end
