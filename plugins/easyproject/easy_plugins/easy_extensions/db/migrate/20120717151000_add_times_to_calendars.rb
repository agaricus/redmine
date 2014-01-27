class AddTimesToCalendars < ActiveRecord::Migration
  def up
    table = (table_exists?(:easy_user_working_time_calendars) ? :easy_user_working_time_calendars : :easy_user_time_calendars)
    add_column table, :time_from, :datetime, {:null => true}
    add_column table, :time_to, :datetime, {:null => true}
  end

  def down
    table = (table_exists?(:easy_user_working_time_calendars) ? :easy_user_working_time_calendars : :easy_user_time_calendars)
    remove_column table, :time_from
    remove_column table, :time_to
  end
end
