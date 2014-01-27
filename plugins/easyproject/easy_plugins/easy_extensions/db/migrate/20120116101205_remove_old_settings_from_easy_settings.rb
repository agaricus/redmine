class RemoveOldSettingsFromEasySettings < ActiveRecord::Migration
  def self.up
    if issue_columns = Setting.find(:first, :conditions => {:name => 'issue_list_default_columns'})
      issue_columns.destroy
    end
    if user_columns = EasySetting.find(:first, :conditions => {:name => 'user_list_default_columns'})
      user_columns.destroy
    end
    if project_columns = EasySetting.find(:first, :conditions => {:name => 'project_list_default_columns'})
      project_columns.destroy
    end
  end

  def self.down
  end
end
