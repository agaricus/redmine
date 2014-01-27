class AddIndexToProjectRoleActivities < ActiveRecord::Migration
  def self.up
    add_index :projects_activity_roles, [:project_id, :activity_id, :role_id], :unique => true, :name => 'idx_projects_activity_roles_1'
  end

  def self.down
  end
end
