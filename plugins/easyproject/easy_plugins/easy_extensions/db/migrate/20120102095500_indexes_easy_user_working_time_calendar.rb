class IndexesEasyUserWorkingTimeCalendar < ActiveRecord::Migration
  def self.up

    table = (table_exists?(:easy_user_working_time_calendars) ? :easy_user_working_time_calendars : :easy_user_time_calendars)
    add_index table, :parent_id
    add_index table, :user_id
    add_index table, :position

    table = (table_exists?(:easy_user_working_time_calendar_holidays) ? :easy_user_working_time_calendar_holidays : :easy_user_time_calendar_holidays)
    add_index table, :calendar_id

    table = (table_exists?(:easy_user_working_time_calendar_exceptions) ? :easy_user_working_time_calendar_exceptions : :easy_user_time_calendar_exceptions)
    add_index table, :calendar_id
  end

  def self.down
  end
end