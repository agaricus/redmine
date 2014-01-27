class ProjectActivity < ActiveRecord::Base
  self.table_name = 'projects_activities'
    
  belongs_to :project
  belongs_to :activity, :class_name => 'TimeEntryActivity', :foreign_key => 'activity_id'
  
end