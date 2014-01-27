class AddEasySettingsIssueCreatedOnDateFormat < ActiveRecord::Migration
  def self.up
    EasySetting.create :name => 'issue_created_on_date_format', :value => 'datetime'
  end

  def self.down
    EasySetting.where(:name => 'issue_created_on_date_format').destroy_all
  end
end
