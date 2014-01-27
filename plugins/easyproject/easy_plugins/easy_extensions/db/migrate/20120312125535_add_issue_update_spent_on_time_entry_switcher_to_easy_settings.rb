class AddIssueUpdateSpentOnTimeEntrySwitcherToEasySettings < ActiveRecord::Migration
  def self.up
    EasySetting.create(:name => 'time_entry_spent_on_at_issue_update_enabled', :value => false)
  end

  def self.down
    EasySetting.where(:name => 'time_entry_spent_on_at_issue_update_enabled').destroy_all
  end
end
