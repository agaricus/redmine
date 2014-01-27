class AddEasySettingsDefaultIssueSorting < ActiveRecord::Migration
  def self.up
    EasySetting.create :name => 'issue_default_sorting_array', :value => [['priority', 'desc'], 'due_date']
    EasySetting.create :name => 'issue_default_sorting_string_short', :value => 'priority:desc,due_date:asc'
    EasySetting.create :name => 'issue_default_sorting_string_long', :value => "#{IssuePriority.table_name}.position DESC, #{Issue.table_name}.due_date ASC"
  end

  def self.down
    EasySetting.where(:name => 'issue_default_sorting_array').destroy_all
    EasySetting.where(:name => 'issue_default_sorting_string_short').destroy_all
    EasySetting.where(:name => 'issue_default_sorting_string_long').destroy_all
  end
end