class EasyUserTimeCalendar < ActiveRecord::Base

  default_scope lambda { order("#{EasyUserTimeCalendar.table_name}.position ASC") }

  belongs_to :user
  has_many :holidays, :class_name => "EasyUserTimeCalendarHoliday", :foreign_key => 'calendar_id', :dependent => :destroy
  has_many :exceptions, :class_name => "EasyUserTimeCalendarException", :foreign_key => 'calendar_id', :dependent => :destroy

  acts_as_tree :dependent => :destroy
  acts_as_list :scope => :user_id

  validates_length_of :name, :in => 1..255, :allow_nil => false
  validates_numericality_of :default_working_hours, :allow_nil => false, :message => :invalid, :greater_than_or_equal_to => 0.0, :less_than_or_equal_to => 24.0
  validates :first_day_of_week, :presence => true

  before_save :change_default
  before_save :change_default_working_hours
  after_initialize :set_default_values
  after_update :propagate_inherited_values

  scope :templates, lambda { where("#{EasyUserTimeCalendar.table_name}.user_id IS NULL AND #{EasyUserTimeCalendar.table_name}.parent_id IS NULL") }

  attr_reader :current_date, :startdt, :enddt

  def self.find_by_user(user)
    user_id = nil
    if user.is_a?(User)
      user_id = user.id
    else
      user_id = user.to_i if user.respond_to?(:to_i)
    end
    return nil if user_id.nil? || !user_id.is_a?(Fixnum) || user_id <= 0

    EasyUserTimeCalendar.where(:user_id => user_id).where("#{EasyUserTimeCalendar.table_name}.parent_id IS NOT NULL").first
  end

  def self.default
    self.where(:is_default => true, :user_id => nil, :parent_id => nil).first
  end

  def self.human_attribute_name(attribute, *args)
    l("activerecord.attributes.easy_user_working_time_calendar.#{attribute}")
  end

  def name=(arg)
    # cannot change name of a builtin calendar
    super unless self.builtin?
  end

  def assign_to_user(user, preserve_calendar_exceptions = false)
    return false unless user.is_a?(User)

    attributes = self.attributes.dup.except('id', 'user_id', 'parent_id', 'is_default', 'builtin')
    attributes['user_id'] = user.id
    attributes['parent_id'] = self.id
    attributes['is_default'] = false

    old_calendar = self.class.find_by_user(user)
    new_calendar = self.class.new(attributes)

    if preserve_calendar_exceptions
      new_calendar.exceptions << self.exceptions.collect{|e| e.dup}
    end

    new_calendar.save!
    old_calendar.destroy if old_calendar
  end

  def reset
    exceptions.clear
    if parent
      exceptions << parent.exceptions.collect{|e| e.dup}
      self.default_working_hours = parent.default_working_hours
      self.time_from             = parent.time_from
      self.time_to               = parent.time_to
      save
    end
  end

  def initialize_inner_calendar(current_date = nil)
    if current_date.is_a?(String)
      @current_date = begin; current_date.to_date; rescue; end
    else
      @current_date = current_date
    end
    @current_date ||= Date.today
    @startdt = Date.civil(@current_date.year, @current_date.month, 1)
    @enddt = (@startdt >> 1)-1
    # starts from the first day of the week
    @startdt = @startdt - (@startdt.cwday - self.first_wday)%7
    # ends on the last day of the week
    @enddt = @enddt + (self.last_wday - @enddt.cwday)%7
  end

  def first_day_of_week
    self.parent.nil? ? read_attribute(:first_day_of_week) : self.parent.first_day_of_week
  end

  def translated_name
    if self.builtin?
      l("easy_user_working_time_calendar_names.#{self.name.downcase}".to_sym)
    else
      self.name
    end
  end

  def working_time(day)
    if self.working_day?(day)
      if exc = self.exception(day)
        return exc.working_hours
      else
        @attendance_time ||= ((self.time_to - self.time_from).seconds / 1.hour)
        return @attendance_time
      end
    else
      return 0.0
    end
  end

  def sum_working_time(from=nil, to=nil)
    from ||= Date.today
    to ||= Date.today
    sum = 0.0
    from.upto(to){|day| sum += self.working_time(day)}
    sum
  end

  def working_hours(day)
    if exc = self.exception(day)
      exc.working_hours
    elsif self.holiday?(day)
      0.0
    else
      if self.weekend?(day)
        0.0
      else
        self.default_working_hours
      end
    end
  end

  def working_hours_between(day_from = nil, day_to = nil)
    h = {}
    day_from ||= Date.today
    day_to ||= Date.today

    self.exception_between(day_from, day_to).each do |e|
      h[e.exception_date] ||= e.working_hours
    end

    day_from.upto(day_to) do |day|
      h[day] ||= 0.0 if self.holiday?(day)
      h[day] ||= 0.0 if self.weekend?(day)
      h[day] ||= self.default_working_hours
    end

    h
  end

  def working_days(from = nil, to = nil)
    from ||= Date.today
    to ||= Date.today
    i=0
    from.upto(to){|day| i += 1 if self.working_day?(day)}
    i
  end

  def sum_working_hours(from = nil, to = nil)
    from ||= Date.today
    to ||= Date.today
    sum = 0.0
    from.upto(to){|day| sum += self.working_hours(day)}
    sum
  end

  def sum_working_hours_ignore_holidays(from = nil, to = nil)
    from ||= Date.today
    to ||= Date.today
    sum = 0.0
    from.upto(to) do |day|
      if !self.weekend?(day)
        sum += self.default_working_hours
      end
    end
    sum
  end

  def weekend?(day)
    day.cwday == 6 || day.cwday == 7
  end

  def working_day?(day)
    self.working_hours(day) > 0.0
  end

  def holiday(day)
    (self.parent.nil? ? self : self.parent).holidays.detect{|ex| ex.is_repeating? ? (ex.holiday_date.day == day.day && ex.holiday_date.month == day.month) : (ex.holiday_date == day)}
  end

  def holiday?(day)
    !self.holiday(day).nil?
  end

  def exception(day)
    (self.parent.nil? ? self.exceptions : self.exceptions + self.parent.exceptions).detect{|ex| ex.exception_date == day}
  end

  def exception_between(day_from, day_to)
    e = self.exceptions.where(["#{EasyUserTimeCalendarException.table_name}.exception_date BETWEEN ? AND ?", day_from, day_to])
    e += self.parent.exceptions.where(["#{EasyUserTimeCalendarException.table_name}.exception_date BETWEEN ? AND ?", day_from, day_to]) unless self.parent_id.blank?
    e
  end

  def exception?(day)
    !self.exception(day).nil?
  end

  def first_wday
    @first_wday ||= (self.first_day_of_week - 1)%7 + 1
  end

  def last_wday
    @last_wday ||= (self.first_wday + 5)%7 + 1
  end

  def prev_start_date
    @current_date - 1.month
  end

  def next_start_date
    @enddt + 1.day
  end

  def month
    @current_date.month
  end

  def year
    @current_date.year
  end

  def css_classes(day)
    s = []
    s << 'today' if Date.today == day
    s << 'weekend' if self.weekend?(day)
    s << 'holiday' if self.holiday?(day)
    s << 'exception' if self.exception?(day)
    s.join(' ')
  end

  def minutes_per_day
    self.default_working_hours * 60
  end

  def minutes_per_week
    self.minutes_per_day * 5
  end

  private

  def change_default
    if self.is_default? && self.user_id.blank? && self.is_default_changed?
      self.class.where(:user_id => nil, :parent_id => nil).update_all(:is_default => false)
    end
  end

  def set_default_values
    return unless self.class.column_names.include?('time_from')
    t = Time.now
    self.time_from = Time.utc(t.year, t.month, t.day, 9) if self.time_from.blank?
    self.time_to = Time.utc(t.year, t.month, t.day, 17, 30) if self.time_to.blank?
  end

  def change_default_working_hours
    return unless self.class.column_names.include?('time_from')
    if !self.time_from.blank? && !self.time_to.blank? && self.default_working_hours.blank?
      self.default_working_hours = (self.time_to - self.time_from) / 3600
    end
  end

  def propagate_inherited_values
    return unless self.class.column_names.include?('time_from')
    if (default_working_hours_changed? || time_from_changed? || time_to_changed?) && children.any?
      children.where(:default_working_hours => default_working_hours_was).update_all(:default_working_hours => default_working_hours)
      children.where(:time_from => time_from_was).update_all(:time_from => time_from)
      children.where(:time_to => time_to_was).update_all(:time_to => time_to)
    end
  end

end
