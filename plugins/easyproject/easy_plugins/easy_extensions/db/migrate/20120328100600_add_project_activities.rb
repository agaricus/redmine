class AddProjectActivities < ActiveRecord::Migration
  def self.up

    create_table :projects_activities, :id => false  do |t|
      t.column :project_id, :integer, {:null => false}
      t.column :activity_id, :integer, {:null => false}
    end
    
    add_index :projects_activities, [:project_id, :activity_id], :unique => true, :name => 'idx_projects_activities_1'
    add_index :projects_activities, [:project_id], :name => 'idx_projects_activities_2'
  end

  def self.down
    drop_table :projects_activities
  end
end
