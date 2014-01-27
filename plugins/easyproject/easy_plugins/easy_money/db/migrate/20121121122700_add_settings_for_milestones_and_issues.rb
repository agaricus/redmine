class AddSettingsForMilestonesAndIssues < ActiveRecord::Migration
  def self.up

    EasyMoneySettings.create :name => 'use_easy_money_for_versions', :project_id => nil, :value => '0'
    EasyMoneySettings.create :name => 'use_easy_money_for_issues', :project_id => nil, :value => '0'

  end

  def self.down
  end
end