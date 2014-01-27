class AddProjectMappingToEasyAttendanceActivities < ActiveRecord::Migration
  def self.up
    add_column :easy_attendance_activities, :project_mapping, :boolean, {:null => false, :default => false}
    add_column :easy_attendance_activities, :mapped_project_id, :integer, {:null => true}
    add_column :easy_attendance_activities, :mapped_time_entry_activity_id, :integer, {:null => true}
  end

  def self.down
    remove_column :easy_attendance_activities, :project_mapping
    remove_column :easy_attendance_activities, :mapped_project_id
    remove_column :easy_attendance_activities, :mapped_time_entry_activity_id
  end
end
