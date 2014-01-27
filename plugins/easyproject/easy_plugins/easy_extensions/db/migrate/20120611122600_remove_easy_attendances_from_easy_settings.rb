class RemoveEasyAttendancesFromEasySettings < ActiveRecord::Migration
  def self.up
    EasySetting.find(:all, :conditions => {:name => 'easy_attendance_enabled'}).each(&:destroy)
  end

  def self.down
  end
end