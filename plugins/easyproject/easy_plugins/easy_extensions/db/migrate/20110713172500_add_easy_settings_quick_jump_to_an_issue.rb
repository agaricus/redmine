class AddEasySettingsQuickJumpToAnIssue < ActiveRecord::Migration
  def self.up
    EasySetting.create :name => 'quick_jump_to_an_issue', :value => 'false'
  end

  def self.down
    EasySetting.where(:name => 'quick_jump_to_an_issue').destroy_all
  end
end
