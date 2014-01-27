class CreateProjectsActivityRoles < ActiveRecord::Migration
  def self.up
    create_table :projects_activity_roles, :id => false do |t|
      t.integer :project_id
      t.integer :activity_id
      t.integer :role_id
    end
    
    add_index :projects_activity_roles, :project_id
    add_index :projects_activity_roles, [:project_id, :role_id]
  end

  def self.down
    drop_table :projects_activity_roles
  end
end
