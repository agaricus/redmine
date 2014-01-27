class CreateEasyUserWorkingTimeCalendar < ActiveRecord::Migration
  def self.up
    create_table :easy_user_time_calendars do |t|
      t.column :name, :string, { :null => false }
      t.column :user_id, :integer, { :null => true }
      t.column :parent_id, :integer, { :null => true }
      t.column :type, :string, { :null => false, :limit => 2048 }
      t.column :default_working_hours, :float, { :null => false }
      t.column :first_day_of_week, :integer, { :null => false, :default => 1 }
      t.column :builtin, :boolean, { :null => false, :default => false }
      t.column :is_default, :boolean, { :null => false, :default => false }
      t.column :position, :integer, { :null => true, :default => 1 }
    end
  end

  def self.down
    table = (table_exists?(:easy_user_working_time_calendars) ? :easy_user_working_time_calendars : :easy_user_time_calendars)
    drop_table table
  end
end