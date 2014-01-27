class AddShowIssueCustomFieldValuesLayoutToEasySettings < ActiveRecord::Migration
  def change
    EasySetting.create(:name => 'show_issue_custom_field_values_layout', :value => 'two_columns')
  end
end
