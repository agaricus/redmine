class EpmUserAllocationWorkingPlan < EasyPageModule

  include EasyUtils::DateUtils

  def category_name
    @category_name ||= 'users'
  end

  def permissions
    @permissions ||= [:view_my_easy_user_allocations]
  end


  def get_show_data(settings, user, page_context={})

    from = (begin; settings['start_date'].to_date rescue Date.today; end).beginning_of_week
    to = from + 4.days

    calendar = EasyAttendances::Calendar.new(from, current_language, :week)

    current_working_plans = user.easy_user_allocation_working_plan_items.in_date(from).includes(:issue => :project)
    scope = user.easy_user_allocations.where(:date => from..to)
    scope = scope.where("#{EasyUserAllocation.table_name}.issue_id NOT IN (?)", current_working_plans.pluck(:issue_id)) if current_working_plans.any?

    scope.includes(:issue => :status).where({:issue_statuses => {:is_closed => false}}).group(:issue_id).select(:issue_id).each do |u|
      current_working_plans << EasyUserAllocationWorkingPlanItem.new(:user => user, :issue => u.issue, :date => from)
    end

    time_entries = TimeEntry.where(:user_id => user.id, :issue_id => current_working_plans.map(&:issue_id), :spent_on => from..to).select([:spent_on, :hours, :issue_id]).inject({}) do |mem, var|
      mem[var.spent_on] ||= {}
      mem[var.spent_on][var.issue_id] ||= 0
      mem[var.spent_on][var.issue_id] += var.hours
      mem
    end
    can_edit ||= {}
    can_edit[:my_working_plan] = true if User.current.allowed_to?(:edit_my_easy_user_allocations_plan, nil, :global => true) ||  User.current.allowed_to?(:edit_easy_user_allocations, nil, :global => true)
    current_working_plans = current_working_plans.sort_by{|w| w.issue.subject}

    return {:user => user, :current_working_plans => current_working_plans, :from => from, :to => to, :time_entries => time_entries, :calendar => calendar, :can_edit => can_edit}
  end

  def module_allowed?
    if EasyUserAllocationWorkingPlanItem.is_enabled
      super
    else
      return false
    end
  end

end
