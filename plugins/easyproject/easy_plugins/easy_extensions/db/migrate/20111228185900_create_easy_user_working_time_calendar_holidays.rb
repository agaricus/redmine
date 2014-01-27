class CreateEasyUserWorkingTimeCalendarHolidays < ActiveRecord::Migration
  def self.up
    create_table :easy_user_time_calendar_holidays do |t|
      t.column :calendar_id, :integer, { :null => false }
      t.column :name, :string, { :null => false, :default => '' }
      t.column :holiday_date, :date, { :null => false }
      t.column :is_repeating, :boolean, { :null => false, :default => true }
    end
  end

  def self.down
    table = (table_exists?(:easy_user_working_time_calendar_holidays) ? :easy_user_working_time_calendar_holidays : :easy_user_time_calendar_holidays)
    drop_table table
  end
end