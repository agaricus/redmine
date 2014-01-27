class ChangeDefaultFilterInEasyAttendances < ActiveRecord::Migration
  def self.up
    EasySetting.find(:all, :conditions => {:name => 'easy_attendance_query_default_filters'}).each do |s|
      s.value = {'arrival' => {:operator=>'date_period_1', :values=> {:period => 'current_week', :from => '', :to => ''}}, 'user_id' => {:operator=>'=', :values => ['me']}}
      s.save!
    end
  end

  def self.down
  end
end
