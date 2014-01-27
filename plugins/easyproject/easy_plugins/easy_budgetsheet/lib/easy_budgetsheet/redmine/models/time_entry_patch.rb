module EasyBudgetsheet
  module TimeEntryPatch

    def self.included(base)
      base.extend(ClassMethods)
      base.send(:include, InstanceMethods)

      base.class_eval do

        before_save :check_easy_is_billable

        safe_attributes 'easy_is_billable', 'easy_billed'

        def easy_is_billable
          v = super
          if v.nil?
            EasySetting.value(:billable_things_default_state)
          else
            v
          end
        end

        def easy_is_billable?
          !!self.easy_is_billable
        end

        private

        def check_easy_is_billable
          if !self.easy_is_billable? && self.easy_billed?
            self.easy_billed = '0'
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
EasyExtensions::PatchManager.register_model_patch 'TimeEntry', 'EasyBudgetsheet::TimeEntryPatch'
