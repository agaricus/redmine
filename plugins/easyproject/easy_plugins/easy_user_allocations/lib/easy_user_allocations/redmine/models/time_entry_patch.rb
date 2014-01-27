module EasyUserAllocations
  module TimeEntryPatch

    def self.included(base)
      base.extend(ClassMethods)
      base.send(:include, InstanceMethods)

      base.class_eval do

        after_save :recalculate_user_allocation
        after_destroy :recalculate_user_allocation

        private

        def recalculate_user_allocation
          # return if !EasyUserAllocation.table_exists? || self.new_record? || self.project.easy_is_easy_template? || self.mass_operations_in_progress == true
          # u = self.issue.assigned_to if self.issue
          # EasyUserAllocation.ensure_time_allocation_for_user(u, self.issue) if u
        end

      end
    end

    module InstanceMethods

    end

    module ClassMethods

    end

  end

end
EasyExtensions::PatchManager.register_model_patch 'TimeEntry', 'EasyUserAllocations::TimeEntryPatch'
