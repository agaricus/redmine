class AddProjectDateSettings < ActiveRecord::Migration
  def self.up
    EasySetting.create! :name => 'project_calculate_start_date', :value => true
    EasySetting.create! :name => 'project_calculate_due_date', :value => false
  end
  
  def self.down
    EasySetting.where(:name => 'project_calculate_start_date').destroy_all
    EasySetting.where(:name => 'project_calculate_due_date').destroy_all
  end
end