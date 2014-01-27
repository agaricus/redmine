class MigrateProjectActivities < ActiveRecord::Migration
  def self.up
    ProjectActivity.connection.execute("
INSERT INTO #{ProjectActivity.table_name} (project_id, activity_id)
SELECT p.id, e.id
FROM #{Enumeration.table_name} e
CROSS JOIN #{Project.table_name} p
WHERE e.type = 'TimeEntryActivity' AND e.project_id IS NULL AND e.active = #{Enumeration.connection.quoted_true}")

    ProjectActivity.connection.execute("DELETE FROM #{ProjectActivity.table_name}
WHERE EXISTS(
		SELECT e.project_id, e.parent_id
FROM
		#{Enumeration.table_name} e
WHERE
		e.type = 'TimeEntryActivity'
		AND e.project_id IS NOT NULL
		AND e.active = #{Enumeration.connection.quoted_false}
AND e.project_id = projects_activities.project_id
AND e.parent_id = projects_activities.activity_id
)")

    ProjectActivity.connection.execute("INSERT INTO #{ProjectActivity.table_name} (project_id, activity_id)
SELECT e1.project_id, e1.parent_id
FROM #{Enumeration.table_name} e1
INNER JOIN #{Enumeration.table_name} e2 ON e2.id = e1.parent_id AND e2.active = #{Enumeration.connection.quoted_false}
WHERE e1.type = 'TimeEntryActivity' AND e1.project_id IS NOT NULL AND e1.active = #{Enumeration.connection.quoted_true}")
  end

  def self.down
  end
end
