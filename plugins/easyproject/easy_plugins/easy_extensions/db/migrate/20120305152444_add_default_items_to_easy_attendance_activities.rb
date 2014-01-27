# encoding: utf-8
class AddDefaultItemsToEasyAttendanceActivities < ActiveRecord::Migration
  def self.up
    EasyAttendanceActivity.create(:name => 'Kancelář', :is_default => true, :at_work => true, :position => 1, :internal_name => 'office', :non_deletable => true)
    EasyAttendanceActivity.create(:name => 'Home office', :is_default => false, :at_work => true, :position => 2)
    EasyAttendanceActivity.create(:name => 'Dovolená', :is_default => false, :at_work => false, :position => 3)
    EasyAttendanceActivity.create(:name => 'Nemoc', :is_default => false, :at_work => false, :position => 4)
    
    EasySetting.create(:name => 'easy_attendance_query_list_default_columns', :value => ['arrival', 'departure', 'easy_attendance_activity'])
    EasySetting.create(:name => 'easy_attendance_query_default_filters', :value => {'arrival'=> {:operator=>'date_period_1', :values=> {:period => 'current_week', :from => '', :to => ''}}})
  end

  def self.down
    EasyAttendanceActivity.delete_all('name IN("Kancelář","Home office","Dovolená","Nemoc")')
    EasySetting.where(:name => 'easy_version_query_list_default_columns').destroy_all
    EasySetting.where(:name => 'easy_attendance_query_default_filters').destroy_all
  end
end
