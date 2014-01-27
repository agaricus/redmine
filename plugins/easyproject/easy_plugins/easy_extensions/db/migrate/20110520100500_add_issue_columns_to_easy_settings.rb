class AddIssueColumnsToEasySettings < ActiveRecord::Migration
  def self.up
    EasySetting.create :name => 'new_issue_columns_list', :value => []
    EasySetting.create :name => 'edit_issue_columns_list', :value => []
  end

  def self.down
    EasySetting.where(:name => 'new_issue_columns_list').destroy_all
    EasySetting.where(:name => 'edit_issue_columns_list').destroy_all
  end
end
