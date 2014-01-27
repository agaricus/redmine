class AddDefaultProjectPageToEasySettings < ActiveRecord::Migration
  def self.up
    EasySetting.create(:name => 'default_project_page', :value => 'project_overview')
  end

  def self.down
    EasySetting.where(:name => 'default_project_page').destroy_all
  end
end
