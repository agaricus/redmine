class AddEasyAttendanceSwitcherToEasySettings < ActiveRecord::Migration
  def self.up
    EasySetting.create(:name => 'easy_attendance_enabled', :value => false)
  end

  def self.down
    EasySetting.where(:name => 'easy_attendance_enabled').destroy_all
  end
end
