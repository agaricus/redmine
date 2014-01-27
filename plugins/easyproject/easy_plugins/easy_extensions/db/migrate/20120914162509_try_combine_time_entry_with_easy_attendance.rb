class TryCombineTimeEntryWithEasyAttendance < ActiveRecord::Migration
  def up
    EasyAttendance.all.each do |i|
      next unless i.time_entry_id.nil?
      # Find TimeEntry EasyAttendance by attributes. It is a great probability that ptaří together ...
      time_entry = TimeEntry.where(
        :user_id => i.user_id, 
        :project_id => i.easy_attendance_activity.mapped_project && i.easy_attendance_activity.mapped_project.id, 
        :activity_id => i.easy_attendance_activity.mapped_time_entry_activity && i.easy_attendance_activity.mapped_time_entry_activity.id, 
        :easy_range_from => i.arrival,
        :easy_range_to => i.departure).first
      # Save without callback
      i.update_column(:time_entry_id, time_entry.id) if time_entry
            
    end
  end

  def down
  end
end
