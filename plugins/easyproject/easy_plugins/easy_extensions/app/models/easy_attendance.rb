class EasyAttendance < ActiveRecord::Base
  include Redmine::SafeAttributes

  RANGE_FORENOON    = 1
  RANGE_AFTERNOON   = 2
  RANGE_FULL_DAY    = 3

  belongs_to :easy_attendance_activity
  belongs_to :user
  belongs_to :edited_by, :class_name => 'User', :foreign_key => 'edited_by_id'
  belongs_to :time_entry, :class_name => 'TimeEntry', :foreign_key => 'time_entry_id', :dependent => :destroy

  validates :user_id, :easy_attendance_activity_id, :arrival, :presence => true
  validate :easy_attendance_validations

  attr_accessor :new_arrival, :current_user_ip, :range_start_time

  acts_as_event :title => Proc.new {|o| "#{o.easy_attendance_activity.name} : #{format_time(o.arrival, false)}" + ( o.departure ? " - #{format_time(o.departure, false)}" : '')},
    :url => Proc.new {|o| {:controller => 'users', :action => 'show', :id => o.id}},
    :author => Proc.new{|o| o.user},
    :datetime => :arrival,
    :description => Proc.new{|o| }

  acts_as_activity_provider({:author_key => :user_id, :timestamp => :arrival})

  scope :visible, lambda {|*user| }
  scope :non_working, lambda { where(["#{EasyAttendanceActivity.table_name}.at_work = ?", false]).includes(:easy_attendance_activity) }
  scope :between, lambda {|date_from, date_to| where(["#{EasyAttendance.table_name}.arrival BETWEEN ? AND ? AND #{EasyAttendance.table_name}.departure BETWEEN ? AND ?", date_from.beginning_of_day, date_to.end_of_day, date_from.beginning_of_day, date_to.end_of_day])} do
    def sum_spent_time(user_working_time_calendar = nil, return_value_in_hours = false)
      default_working_hours = user_working_time_calendar.default_working_hours if user_working_time_calendar
      default_working_hours ||= 8.0

      inject(0.0) do |memo, att|
        hours = att.spent_time || 0.0

        memo += round_hours_for_day(hours, default_working_hours, default_working_hours / 2, return_value_in_hours)
      end
    end

    def get_spent_time(default_working_hours, half_working_hours, return_value_in_hours = false)
      h = {}
      each do |att|
        h[att.arrival.to_date] = round_hours_for_day(att.spent_time || 0.0, default_working_hours, half_working_hours, return_value_in_hours)
      end
      h
    end
  end

  before_validation :assign_default_activity
  before_save :set_user_ip
  before_save :faktorize_attendances
  after_save :ensure_time_entry, :if => Proc.new {|o| o.easy_attendance_activity_id_changed?}

  safe_attributes 'arrival', 'departure', 'user_id', 'easy_attendance_activity_id', 'range', 'description'

  def self.enabled?
    EasyExtensions::EasyProjectSettings.easy_attendance_enabled == true
  end

  def self.round_hours_for_day(hours, default_working_hours = 8.0, half_working_hours = 4.0, return_value_in_hours = false)
    if hours <= 0.0
      return 0.0
    else
      if hours <= half_working_hours
        if return_value_in_hours
          return half_working_hours
        else
          return 0.5
        end
      else
        if return_value_in_hours
          return default_working_hours
        else
          return 1.0
        end
      end
    end
  end

  def self.new_or_last_attendance(user=nil)
    user ||= User.current
    i = user.get_easy_attendance_last_arrival || self.new
    i.user ||= user

    if i.new_record?
      i.new_arrival = true
      i.arrival = user.user_time_in_zone
    else
      i.new_arrival = false
      i.departure = user.user_time_in_zone
    end

    return i
  end

  def self.office_ip_range
    if self.enabled?
      plugin_settings = Setting.plugin_easy_attendances
      ip_str = plugin_settings.try(:value_at, 'office_ip_range')
      if ip_str.present?
        return IPAddr.new(ip_str)
      end
    end
  end

  def project
    self.time_entry && self.time_entry.project
  end

  def arrival=(value)
    time = nil
    if value.is_a?(Time)
      time = value.round_min_to_quarters
    elsif value.is_a?(String)
      time = begin; value.to_time.round_min_to_quarters; rescue; end;
    end
    # time = time.utc unless time.utc?
    write_attribute(:arrival, time)
  end

  def departure=(value)
    time = nil
    if value.is_a?(Time)
      time = value.round_min_to_quarters
    elsif value.is_a?(String)
      time = begin; value.to_time.round_min_to_quarters; rescue; end;
    end
    # time = time.utc unless time.utc?
    write_attribute(:departure, time)
  end

  # Je to příchod? Pokud není poslední záznam v db s prázdným odchodem tak to je příchod
  def arrival?
    return self.new_arrival
  end

  # Odchází uživatel? Aby mohl odejít tak musel přijít tudíž musí existovat last_attendance a je to tedy opak arrival
  def departure?
    return !self.arrival?
  end

  def morning(time)
    args = [time.year, time.month, time.day, user.current_working_time_calendar.time_from.hour]
    if self.user.time_zone
      Time.use_zone(user.time_zone) do
        Time.zone.local(*args)
      end
    else
      Time.local(*args)
    end
  end

  def evening(time)
    return morning(time) + (self.user.working_hours(time.to_date).to_i).hours
  end

  def start_date(user=nil)
    user ||= self.user
    if user.time_zone
      return user.time_to_date(self.arrival)
    elsif ActiveRecord::Base.default_timezone == :local
      return self.arrival.localtime.to_date
    else
      self.arrival.to_date
    end
  end

  def due_date(user=nil)
    user ||= self.user
    if self.departure
      if user.time_zone
        return user.time_to_date(self.departure)
      elsif ActiveRecord::Base.default_timezone == :local
        return self.departure.localtime.to_date
      else
        self.departure.to_date
      end
    end
  end

  def css_classes
    s = 'easy-attandance'
    s << " #{self.easy_attendance_activity.color_schema}"

    return s
  end

  def spent_time
    if self.departure && self.arrival
      (self.departure - self.arrival) / 1.hour
    end
  end

  def working_time
    if self.arrival && self.user && self.user.current_working_time_calendar
      self.user.current_working_time_calendar.working_hours(self.arrival.to_date)
    end
  end

  def after_create_send_mail
    return if self.easy_attendance_activity.mail.blank?
    return if self.arrival.nil? || self.departure.nil?
    EasyMailer.easy_attendance_added(self).deliver
  end

  def after_update_send_mail
    return if self.easy_attendance_activity.mail.blank?
    return if self.arrival.nil? || self.departure.nil?
    EasyMailer.easy_attendance_updated(self).deliver
  end

  def can_edit?(user=nil)
    user ||= User.current
    return (self.user == user && user.allowed_to?(:edit_own_easy_attendances, nil, :global => true)) || user.allowed_to?(:edit_easy_attendances, nil, :global => true)
  end

  private

  def assign_default_activity
    self.easy_attendance_activity ||= EasyAttendanceActivity.default
  end

  def easy_attendance_validations
    if self.departure && self.arrival
      self.errors.add(:departure,  l(:departure_is_same_as_arrival, :scope => [:easy_attendance])) if self.arrival == self.departure
      self.errors.add(:arrival, l(:arrival_date_error, :scope => [:easy_attendance])) if self.arrival > self.departure
      arel = EasyAttendance.arel_table

      if ea = self.user.easy_attendances.where(arel[:departure].not_eq(nil)).where(arel[:arrival].gt(self.arrival).and(arel[:departure].lt(self.departure)).or(arel[:arrival].lt(self.departure).and(arel[:departure].gt(self.arrival)))).first
        self.errors.add(:base, l(:arrival_already_taken, :scope => [:easy_attendance])) if ea != self
      end
    end
  end

  def faktorize_attendances
    if self.departure && self.arrival && ( (self.departure - self.arrival) > 1.day )
      original_departure = self.departure
      # find first working day if arrival is freeday
      while !self.user.current_working_time_calendar.working_day?(self.arrival.to_date)
        self.arrival += 1.day
      end
      # set current entity departure to arrival day
      self.departure = Time.utc(self.arrival.year, self.arrival.month, self.arrival.day, self.departure.hour, self.departure.min)

      attributes = {:easy_attendance_activity => self.easy_attendance_activity, :user => self.user,
          :arrival_user_ip => self.arrival_user_ip, :departure_user_ip => self.departure_user_ip, :range => self.range}

      Redmine::Hook.call_hook(:easy_attendance_faktorie_attendances_before_create, {:easy_attendance => self, :attributes => attributes})

      # create next entities
      (self.arrival + 1.day).to_date.upto(original_departure.to_date) do |day|
        next unless self.user.current_working_time_calendar.working_day?(day)
        attributes[:arrival] =  Time.utc(day.year, day.month, day.day, self.arrival.hour, self.arrival.min)
        attributes[:departure] = Time.utc(day.year, day.month, day.day, self.departure.hour, self.departure.min)

        EasyAttendance.create(attributes)
      end
    end
  end

  def ensure_time_entry
    return if self.new_record?

    if self.easy_attendance_activity.project_mapping? && self.easy_attendance_activity.mapped_project && self.easy_attendance_activity.mapped_time_entry_activity && self.arrival && self.departure
      te = self.time_entry || self.build_time_entry
      te.project = self.easy_attendance_activity.mapped_project
      te.activity = self.easy_attendance_activity.mapped_time_entry_activity
      te.user = self.user
      te.easy_range_from = self.arrival
      te.easy_range_to = self.departure
      te.hours = (self.departure - self.arrival) / 1.hour
      te.spent_on = self.arrival.to_date
      te.comments = self.description
      te.save!
      self.update_column(:time_entry_id, te.id)
    end
  end

  def set_user_ip
    self.arrival_user_ip = self.current_user_ip if !self.current_user_ip.blank? && !self.arrival.nil? && self.arrival_user_ip.blank?
    self.departure_user_ip = self.current_user_ip if !self.current_user_ip.blank? && !self.departure.nil? && self.departure_user_ip.blank?
  end

end

module EasyAttendances

  class Calendar < Redmine::Helpers::Calendar

    def events=(events)
      @events = events
      @ending_events_by_days = @events.group_by {|event| event.due_date(User.current)}
      @starting_events_by_days = @events.group_by {|event| event.start_date(User.current)}

      days = Hash.new{|hash, key| hash[key] = Array.new}
      @startdt.upto(@enddt) do |day|
        days[day.cweek] << day
      end

      @sorted_events = Hash.new
      days.each do |week, days|
        week_events = Hash.new
        # collect all events in weeek
        days.each do |day|
          @sorted_events[day] = EasyAttendances::EasyAttendanceCalendarDay.new(day, ((@ending_events_by_days[day] || []) + (@starting_events_by_days[day] || [])).uniq)
          #week_events[day] = week_events[day].group_by(&:user).sort_by{|k,v| [v.count, k.name]}
        end

        #groupped_week_events = week_events.values.flatten.group_by(&:user_id)
        # sort every day in week by count of user events in week
        # days.each do |day|
        #   week_events[day].each do |e|
        #     @sorted_events[day][e.first] = e.last.sort_by(&:arrival)
        #   end
        # end
      end
    end

    def events_on(day)
      Array(@sorted_events[day])
    end

  end

  class EasyAttendanceCalendarDay

    def initialize(day, events)
      @day = day
      @sorted_events = ActiveSupport::OrderedHash.new

      grouped_events = events.group_by(&:user)

      ordered_group_events = grouped_events.sort_by{|k,v| [v.count, k.name]}

      ordered_group_events.each do |a|
        @sorted_events[a.first] = a.last.sort_by(&:arrival)
      end
    end

    def events
      @sorted_events
    end

  end
end
