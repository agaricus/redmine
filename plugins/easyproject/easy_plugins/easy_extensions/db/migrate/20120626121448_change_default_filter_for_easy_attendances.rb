class ChangeDefaultFilterForEasyAttendances < ActiveRecord::Migration
  def up
    EasySetting.where(:name => 'easy_attendance_query_default_filters').each do |setting|
      setting.value = {"user_id"=>{:operator=>"=", :values=>["me"]}, "arrival"=>{:operator=>"date_period_1", :values=>{:period=>"current_month", :to=>"", :from=>""}}}
      setting.save!
    end
  end

  def down
  end
end
