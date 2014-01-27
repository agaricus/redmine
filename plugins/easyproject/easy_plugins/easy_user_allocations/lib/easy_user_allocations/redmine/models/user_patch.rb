module EasyUserAllocations
  module UserPatch

    def self.included(base)
      base.extend(ClassMethods)
      base.send(:include, InstanceMethods)

      base.class_eval do

        has_many :easy_user_allocations, :dependent => :destroy, :order => 'date'
        has_many :easy_user_allocation_working_plan_items, :dependent => :destroy

      end
    end

    module InstanceMethods

      def recalculate_allocations(changed_issues, period, changed_issue_ids)
        allocations = self.easy_user_allocations.includes(:issue => :project).where(:date => period[:from]..period[:to], :projects => {:easy_is_easy_template => false}).where(['issues.id NOT IN (?)', changed_issue_ids]).group_by &:issue
        changed_issues.each do |issue_id, data|
          issue = Issue.find(issue_id)
          data['customAllocation'] = data['customAllocation'].inject({}) {|m, (k,v)| m[Date.parse(k)] = v.to_f; m} if data['customAllocation'].is_a?(Hash)

          issue.start_date = Date.parse(data['start']) if data['start']
          issue.due_date = Date.parse(data['end'])
          issue.assigned_to = self
          allocations[issue] = EasyUserAllocation.allocations_for_issue(issue, self, false, :custom_allocations => data['customAllocation'], :resized => data['resized'])
        end
        allocations
      end

    end

    module ClassMethods

    end

  end

end
EasyExtensions::PatchManager.register_model_patch 'User', 'EasyUserAllocations::UserPatch'
