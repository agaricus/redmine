class FillProjectsActivityRoles < ActiveRecord::Migration
  def self.up
    Project.all.each do |project|
      activities = project.send(:active_activities, true)
      unless activities.blank?
        activities.each do |activity|
          member_roles = project.all_members_roles
          unless member_roles.blank?
            member_roles.each do |role|
              project.project_activity_roles << ProjectActivityRole.new(:activity_id => activity.id, :role_id => role.id)
            end
          end
        end
      end
    end
  end

  def self.down
    Project.connection.execute('TRUNCATE projects_activity_roles')
  end
end
