class AddToEasySettingIssueRelations < ActiveRecord::Migration
  def up
  	EasySetting.create(:name => 'display_issue_relations_on_new_form', :value => false)
  end

  def down
  	EasySetting.where(:name => 'display_issue_relations_on_new_form').destroy_all
  end
end
