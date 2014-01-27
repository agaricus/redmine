require 'easy_extensions/easy_scheduler'

module EasyExtensions
  class EpUpdateProjectsTimeEntryExpenses < EasySchedulerTask

    def initialize(project_ids = nil)
      @project_ids = Array.wrap(project_ids)
      super('EpUpdateProjectsTimeEntryExpenses', {:page_url_ident => 'update_project_time_entry_expenses'})
    end

    def execute
      begin
        case @project_ids.size
        when 0
          EasyMoneyTimeEntryExpense.update_all_projects_time_entry_expenses(Project.non_templates.active.has_module(:easy_money).pluck(:id))
        else
          EasyMoneyTimeEntryExpense.update_all_projects_time_entry_expenses(@project_ids)
        end
      rescue
        return false
      end
            
      return true
    end

  end
end