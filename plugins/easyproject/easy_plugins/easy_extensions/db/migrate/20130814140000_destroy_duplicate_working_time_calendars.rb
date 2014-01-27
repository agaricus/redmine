class DestroyDuplicateWorkingTimeCalendars < ActiveRecord::Migration
  def up
    User.all.each do |u|
      calendar = EasyUserWorkingTimeCalendar.find_by_user(u)
      working_calendars = EasyUserWorkingTimeCalendar.arel_table
      if calendar
        EasyUserWorkingTimeCalendar.where(working_calendars[:id].not_eq(calendar.id).and(working_calendars[:user_id].eq(u.id))).destroy_all
      end
    end
  end

  def down
  end
end
