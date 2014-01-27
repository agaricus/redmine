class ShowIssueIdsDefaultly < ActiveRecord::Migration
  def up
    EasySetting.where(:name => 'show_issue_id').each do |setting|
      setting.value = true
      setting.save
    end
    EasySetting.where(:name => 'quick_jump_to_an_issue').each do |setting|
      setting.value = true
      setting.save
    end
  end

  def down
  end
end
