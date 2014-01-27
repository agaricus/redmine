module EasyPatch
  module TimeEntryQueryPatch

    def self.included(base)
      base.send(:include, InstanceMethods)

      base.class_eval do

        def to_new_easy_query
          EasyTimeEntryQuery.new(:project_id => project_id, :name => name, :filters => filters,
            :user_id => user_id, :visibility => visibility, :column_names => column_names,
            :sort_criteria => sort_criteria, :group_by => group_by)
        end

      end
    end

    module InstanceMethods

    end

  end
end
EasyExtensions::PatchManager.register_model_patch 'TimeEntryQuery', 'EasyPatch::TimeEntryQueryPatch'
