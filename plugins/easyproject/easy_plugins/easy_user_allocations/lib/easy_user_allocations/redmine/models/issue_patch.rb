module EasyUserAllocations
  module IssuePatch

    def self.included(base)
      base.extend(ClassMethods)
      base.send(:include, InstanceMethods)

      base.class_eval do

        has_many :easy_user_allocations, :dependent => :destroy
        has_many :easy_user_allocation_working_plan_items, :dependent => :destroy

        scope :all_to_allocate, lambda {
          joins(:project).
            where("#{Issue.table_name}.assigned_to_id IS NOT NULL AND #{Issue.table_name}.due_date IS NOT NULL").
            where(["#{Project.table_name}.easy_is_easy_template = ?", false]).
            where(["#{Project.table_name}.status <> ?", Project::STATUS_ARCHIVED])
        } do
          def allocate!
            each do |issue|
              EasyUserAllocation.allocate_issue!(issue)
            end
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
EasyExtensions::PatchManager.register_model_patch 'Issue', 'EasyUserAllocations::IssuePatch'
