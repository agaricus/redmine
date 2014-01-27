class AddSelectColorSchemaAtIssueToEasySettings < ActiveRecord::Migration
  def change
    EasySetting.create(:name => 'issue_color_scheme_for', :value => 'issue_priority')
  end
end
