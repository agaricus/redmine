class ChangeColorInEasyAttendanceActivities < ActiveRecord::Migration
  def self.up
    remove_column :easy_attendance_activities, :bckg_color
    remove_column :easy_attendance_activities, :color
    add_column :easy_attendance_activities, :color_schema, :string, {:null => true}
  end

  def self.down
    add_column :easy_attendance_activities, :bckg_color, :string, {:null => false, :default => '#C7C7C7'}
    add_column :easy_attendance_activities, :color, :string, {:null => false, :default => '#FFFFFF'}
    remove_column :easy_attendance_activities, :color_schema
  end
end
