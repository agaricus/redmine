class AddDefaultTimesToCalendars < ActiveRecord::Migration
  def up
    if table_exists?(:easy_user_working_time_calendars)
      EasyUserTimeCalendar.table_name = 'easy_user_working_time_calendars'
    end
    EasyUserWorkingTimeCalendar.reset_column_information
    t = Time.now
    time_from = Time.utc(t.year, t.month, t.day, 9)
    time_to = Time.utc(t.year, t.month, t.day, 17, 30)

    EasyUserWorkingTimeCalendar.all.each do |cal|
      cal.time_from = time_from
      cal.time_to = time_to
      cal.save
    end
    
  end

  def down
  end
end
