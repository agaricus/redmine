module EasyPatch
  module TimeEntryActivityPatch

    def self.included(base)
      base.extend(ClassMethods)
      base.send(:include, InstanceMethods)

      base.class_eval do

        acts_as_easy_translate

        has_many :project_activity_roles, :class_name => 'ProjectActivityRole', :foreign_key => 'activity_id'
        has_many :project_activity_roles, :class_name => 'ProjectActivityRole', :foreign_key => 'activity_id', :dependent => :delete_all
        has_and_belongs_to_many :projects, :join_table => 'projects_activity_roles', :foreign_key => 'activity_id'

        after_save :add_to_all_projects
        after_save :remove_from_projects_if_disabled
        after_destroy :delete_time_entry_activities

        private

        def add_to_all_projects
          if active? && !new_record?
            connection.execute("INSERT INTO #{ProjectActivity.table_name} (project_id, activity_id) SELECT p.id, #{self.id} FROM #{Project.table_name} p WHERE p.easy_is_easy_template = #{connection.quoted_false} AND p.status = #{Project::STATUS_ACTIVE} AND NOT EXISTS(SELECT pa.project_id FROM #{ProjectActivity.table_name} pa WHERE pa.project_id = p.id AND pa.activity_id = #{self.id})")
          end
        end

        def delete_time_entry_activities
          connection.execute("DELETE FROM #{ProjectActivity.table_name} WHERE activity_id = #{self.id}")
        end

        def remove_from_projects_if_disabled
          unless active?
            delete_time_entry_activities
          end
        end

      end
    end

    module InstanceMethods

    end

    module ClassMethods

    end
  end
end
EasyExtensions::PatchManager.register_model_patch 'TimeEntryActivity', 'EasyPatch::TimeEntryActivityPatch', :after => 'Enumeration'
