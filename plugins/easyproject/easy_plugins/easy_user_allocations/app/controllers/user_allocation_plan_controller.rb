class UserAllocationPlanController < UserAllocationGanttController

  helper :easy_query
  include EasyQueryHelper
  helper :easy_user_allocation_gantt

  include EasyUtils::DateUtils

  before_filter :get_date

  def index
    params[:tab] = 'working_plan'
    @user = User.find(params[:user_id]) if params[:user_id] && User.current.allowed_to?(:view_easy_user_allocations, nil, :global => true)
    @user ||= User.current

    @calendar = EasyAttendances::Calendar.new(@from, current_language, :week)

    @current_working_plans = @user.easy_user_allocation_working_plan_items.in_date(@from).includes(:issue => :project)
    scope = @user.easy_user_allocations.where(:date => @from..@to)
    scope = scope.where("#{EasyUserAllocation.table_name}.issue_id NOT IN (?)", @current_working_plans.pluck(:issue_id)) if @current_working_plans.any?

    scope.includes(:issue => :status).where({:issue_statuses => {:is_closed => false}}).group(:issue_id).select(:issue_id).each do |u|
      @current_working_plans << EasyUserAllocationWorkingPlanItem.new(:user => @user, :issue => u.issue, :date => @from)
    end

    @time_entries = TimeEntry.where(:user_id => @user.id, :issue_id => @current_working_plans.map(&:issue_id), :spent_on => @from..@to).select([:spent_on, :hours, :issue_id]).inject({}) do |mem, var|
      mem[var.spent_on] ||= {}
      mem[var.spent_on][var.issue_id] ||= 0
      mem[var.spent_on][var.issue_id] += var.hours
      mem
    end
    @can_edit ||= {}
    @can_edit[:my_working_plan] = true if User.current.allowed_to?(:edit_my_easy_user_allocations_plan, nil, :global => true) ||  User.current.allowed_to?(:edit_easy_user_allocations, nil, :global => true)
    @current_working_plans = @current_working_plans.sort_by{|w| w.issue.subject}
  end

  def save_issue
    user = User.find(params[:user_id])
    user ||= User.current
    issue_id = params[:issue_id]
    issue = Issue.find(issue_id)

    if params[:data].blank?
      return render(:json => {:type => 'error'})
    end

    data = params[:data][issue_id]
    data['customAllocation'] = data['customAllocation'].delete_if{|d, v| v.blank?}

    if params[:id]
      @working_plan_item = EasyUserAllocationWorkingPlanItem.find(params[:id])
    else
      @working_plan_item = EasyUserAllocationWorkingPlanItem.where(:issue_id => issue_id, :user_id => user.id, :d_year => @from.year, :d_week => @from.cweek).first
      @working_plan_item ||= EasyUserAllocationWorkingPlanItem.new(:issue_id => issue_id, :user_id => user.id)
    end
    @working_plan_item.date = @from
    @working_plan_item.comment = data[:notes]

    hook_context = {:working_plan_item => @working_plan_item, :params => params, :data => data}
    call_hook(:controller_easy_user_allocation_plan_action_save_issue_before_save_working_plan_item, hook_context)
    @working_plan_item = hook_context[:working_plan_item]
    params = hook_context[:params]
    data = hook_context[:data]

    data.delete(:notes) unless @working_plan_item.comment_changed?

    data_custom_allocation = data['customAllocation'].keys.collect(&:to_date).sort

    unless data_custom_allocation.blank?
      data['start'] = [issue.start_date, data_custom_allocation.first].min
      data['end'] = [issue.due_date, data_custom_allocation.last].max
    else
      data['start'] = issue.start_date
      data['end'] = issue.due_date
    end

    params[:issues] = {issue_id => data}

    if @working_plan_item.save
      save_issues
    else
      render :json => {:type => 'error', :html => @working_plan_item.errors.full_messages.join('<br/>')}
    end
  end

  def recalculate
    user = User.find(params[:user_id])
    user ||= User.current

    issue_id = params[:issue_id]
    issue = Issue.find(issue_id)
    data = params[:data][issue_id]

    begin
      end_date = data['customAllocation'].keys.sort.last.to_date

      data['end'] = issue.due_date >= end_date ? issue.due_date : end_date
    rescue
      data['end'] = issue.due_date
    end

    params[:changed_users] = [{:id => user.id, :issues => {issue_id => {:start => issue.start_date, :end => data['end'], :customAllocation => data['customAllocation']}}}].to_json
    super
  end

  private

  def get_date
    @from = (begin; params[:start_date].to_date rescue Date.today; end).beginning_of_week
    @to = @from + 4.days
  end
end
