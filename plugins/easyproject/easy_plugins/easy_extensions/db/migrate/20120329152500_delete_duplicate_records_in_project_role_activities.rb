class DeleteDuplicateRecordsInProjectRoleActivities < ActiveRecord::Migration
  def self.up
    Project.connection.execute('DROP TABLE IF EXISTS tmp_projects_activity_roles;')

    create_table :tmp_projects_activity_roles, :force => true, :id => false do |t|
      t.column :project_id, :integer, { :null => false }
      t.column :activity_id, :integer, { :null => false }
      t.column :role_id, :integer, { :null => false }
    end

    Project.connection.execute('INSERT INTO tmp_projects_activity_roles (project_id, activity_id, role_id)
SELECT project_id, activity_id, role_id
FROM projects_activity_roles
GROUP BY project_id, activity_id, role_id;')

    Project.connection.execute('DELETE FROM projects_activity_roles;')

    Project.connection.execute('INSERT INTO projects_activity_roles (project_id, activity_id, role_id)
SELECT project_id, activity_id, role_id
FROM tmp_projects_activity_roles;')

    drop_table :tmp_projects_activity_roles
  end

  def self.down
  end
end
