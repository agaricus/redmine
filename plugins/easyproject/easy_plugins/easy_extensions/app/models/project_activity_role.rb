class ProjectActivityRole < ActiveRecord::Base
  self.table_name = 'projects_activity_roles'
  
  validates :project_id, :role_id, :activity_id ,:presence => true
  
  belongs_to :project
  belongs_to :role_activity, :class_name => 'TimeEntryActivity', :foreign_key => 'activity_id'
  belongs_to :role
  
end