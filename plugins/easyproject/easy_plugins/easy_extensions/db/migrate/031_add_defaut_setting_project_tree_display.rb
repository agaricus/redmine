class AddDefautSettingProjectTreeDisplay < ActiveRecord::Migration

  def self.up
    EasySetting.create :name => 'default_projects_tree_display', :value => 'with_siblings'
  end

  def self.down
    EasySetting.where(:name => 'default_projects_tree_display').destroy_all
  end
end