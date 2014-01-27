class ChangeProjectFixedActivityAndEnableActivityRolesEasySettingsValueType < ActiveRecord::Migration
  def self.up
    EasySetting.find(:all, :conditions => "#{EasySetting.table_name}.name = 'project_fixed_activity' OR #{EasySetting.table_name}.name = 'enable_activity_roles'").each do |e|
      e.value = e.value.to_boolean
      e.save
    end
  end

  def self.down
  end
end
