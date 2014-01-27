class ChangeEasySettingsDefaultIssueSorting < ActiveRecord::Migration
  def self.up
    EasySetting.find(:first , :conditions => {:name => 'issue_default_sorting_array'}).update_attributes(:value => [['priority', 'desc'], 'due_date', 'parent'])
    EasySetting.find(:first , :conditions => {:name => 'issue_default_sorting_string_short'}).update_attributes(:value => 'priority:desc,due_date:asc,parent:asc')
    EasySetting.find(:first , :conditions => {:name => 'issue_default_sorting_string_long'}).update_attributes(:value => "#{IssuePriority.table_name}.position DESC, #{Issue.table_name}.due_date , #{Issue.table_name}.parent_id ")
  end

  def self.down
    EasySetting.find(:first , :conditions => {:name => 'issue_default_sorting_array'}).update_attributes(:value => [['priority', 'desc'], 'due_date'])
    EasySetting.find(:first , :conditions => {:name => 'issue_default_sorting_string_short'}).update_attributes(:value => 'priority:desc,due_date:asc')
    EasySetting.find(:first , :conditions => {:name => 'issue_default_sorting_string_long'}).update_attributes(:value => "#{IssuePriority.table_name}.position DESC, #{Issue.table_name}.due_date ASC")
  end
end