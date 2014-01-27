class AddDefaultColumnsToEasyQuerySettings < ActiveRecord::Migration
  def self.up
    EasySetting.create(:name => 'easy_budget_sheet_query_list_default_columns', :value => ['spent_on', 'user', 'activity', 'issue', 'hours'])
    EasySetting.create(:name => 'easy_budget_sheet_query_grouped_by', :value => 'project')
  end

  def self.down
  end
end
