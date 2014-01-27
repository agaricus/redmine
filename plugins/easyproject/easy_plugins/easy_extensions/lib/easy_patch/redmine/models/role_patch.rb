module EasyPatch
  module RolePatch

    def self.included(base)
      base.extend(ClassMethods)
      base.send(:include, InstanceMethods)

      base.class_eval do

        acts_as_easy_translate

        has_and_belongs_to_many :activities, :join_table => 'projects_activity_roles', :class_name => 'TimeEntryActivity', :association_foreign_key => 'activity_id'
        has_and_belongs_to_many :projects, :join_table => 'projects_activity_roles'

        has_many :project_activity_roles, :class_name => 'ProjectActivityRole'
        has_many :projects, :through => :project_activity_roles
        has_many :role_activities, :through => :project_activity_roles

        has_and_belongs_to_many :easy_queries, :join_table => "#{table_name_prefix}easy_queries_roles#{table_name_suffix}", :foreign_key => 'role_id'

        class << self

        end

      end
    end

    module InstanceMethods

    end

    module ClassMethods

    end

  end

end
EasyExtensions::PatchManager.register_model_patch 'Role', 'EasyPatch::RolePatch'
