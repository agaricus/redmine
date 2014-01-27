class AddEasyStartDateToProjects < ActiveRecord::Migration
  def self.up
    add_column :projects, :easy_start_date, :date
  end
  
  def self.down
    remove_column :projects, :easy_start_date
  end
end