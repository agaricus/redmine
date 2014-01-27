class AddTypeToEasyUserWorkingTimeCalendar < ActiveRecord::Migration
  def self.up

    EasyUserWorkingTimeCalendar.reset_column_information
    EasyUserTimeCalendarException.reset_column_information
    EasyUserTimeCalendarHoliday.reset_column_information

    if table_exists?(:easy_user_working_time_calendars)
      rename_table :easy_user_working_time_calendars, :easy_user_time_calendars
      # reverse earlier setting.
      EasyUserTimeCalendar.table_name = 'easy_user_time_calendars'
      EasyUserWorkingTimeCalendar.table_name = 'easy_user_time_calendars'
      EasyUserTimeCalendar.reset_column_information
    end

    if table_exists?(:easy_user_working_time_calendar_exceptions)
      rename_table :easy_user_working_time_calendar_exceptions, :easy_user_time_calendar_exceptions
    end

    if table_exists?(:easy_user_working_time_calendar_holidays)
      rename_table :easy_user_working_time_calendar_holidays, :easy_user_time_calendar_holidays
    end

    if !column_exists?(:easy_user_time_calendars, :type)
      add_column :easy_user_time_calendars, :type, :string, {:null => true, :limit => 2048}

      EasyUserWorkingTimeCalendar.reset_column_information
      EasyUserTimeCalendarException.reset_column_information
      EasyUserTimeCalendarHoliday.reset_column_information

      EasyUserTimeCalendar.update_all(:type => 'EasyUserWorkingTimeCalendar')

      change_column  :easy_user_time_calendars, :type, :string, {:null => false, :limit => 2048}
    end

    EasyUserWorkingTimeCalendar.reset_column_information
    EasyUserTimeCalendarException.reset_column_information
    EasyUserTimeCalendarHoliday.reset_column_information

  end

  def self.down
  end

end