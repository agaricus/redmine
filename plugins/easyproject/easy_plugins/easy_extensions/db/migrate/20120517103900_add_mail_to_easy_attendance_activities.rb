class AddMailToEasyAttendanceActivities < ActiveRecord::Migration
  def self.up
    add_column :easy_attendance_activities, :mail, :string, {:null => true}
  end

  def self.down
    remove_column :easy_attendance_activities, :mail
  end
end
