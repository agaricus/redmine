class CreateEasyUserWorkingTimeCalendarExceptions < ActiveRecord::Migration
  def self.up
    create_table :easy_user_time_calendar_exceptions do |t|
      t.column :calendar_id, :integer, { :null => false }
      t.column :exception_date, :date, { :null => false }
      t.column :working_hours, :float, { :null => false }
    end
  end

  def self.down
    table = (table_exists?(:easy_user_working_time_calendar_exceptions) ? :easy_user_working_time_calendar_exceptions : :easy_user_time_calendar_exceptions)
    drop_table table
  end
end