class AddShowIssueIdToEasySettings < ActiveRecord::Migration
  def self.up
    EasySetting.create(:name => 'show_issue_id', :value => false)
  end

  def self.down
    EasySetting.where(:name => 'show_issue_id').destroy_all
  end
end
