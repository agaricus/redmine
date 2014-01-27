class AddToEasySettingsAttendanceUseTimeSelect < ActiveRecord::Migration
  def change
    EasySetting.create(:name => 'easy_attendance_use_time_select', :value => false)
  end
end
