class AddEasySettingsForIssue < ActiveRecord::Migration
  def up
    EasySetting.create(:name => 'issue_recalculate_attributes', :value => true)
  end

  def down
    EasySetting.where(:name => 'issue_recalculate_attributes').destroy_all
  end
end
