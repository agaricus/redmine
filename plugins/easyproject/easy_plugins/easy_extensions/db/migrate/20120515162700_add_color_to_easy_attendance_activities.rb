class AddColorToEasyAttendanceActivities < ActiveRecord::Migration
  def self.up
    add_column :easy_attendance_activities, :bckg_color, :string, {:null => false, :default => '#C7C7C7'}
    add_column :easy_attendance_activities, :color, :string, {:null => false, :default => '#FFFFFF'}
  end

  def self.down
    remove_column :easy_attendance_activities, :bckg_color
    remove_column :easy_attendance_activities, :color
  end
end
