class AddEasySettingsProjectListDefaultColumns < ActiveRecord::Migration
  def self.up
    EasySetting.create :name => 'project_list_default_columns', :value => ["name", "description"]
  end

  def self.down
    EasySetting.where(:name => 'project_list_default_columns').destroy_all
  end
end