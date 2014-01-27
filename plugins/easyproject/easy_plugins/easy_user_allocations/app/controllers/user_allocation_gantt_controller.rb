require_dependency 'utils/dateutils'

class UserAllocationGanttController < ApplicationController
  include EasyUtils::DateUtils

  helper :easy_query
  include EasyQueryHelper
  helper :easy_user_allocation_gantt
  include EasyUserAllocationGanttHelper
  helper :sort
  include SortHelper

  menu_item :user_allocations

  before_filter :authorize_global
  before_filter :find_optional_project
  before_filter :get_period, :only => [:data, :data_by_project, :recalculate, :save_issues]
  before_filter :prepare_variables, :only => [:data]

  def index
    params[:tab] = 'gantt'
    retrieve_query(EasyUserAllocationQuery)

    @fullscreen = request.xhr? && params[:fullscreen]

    if @query.valid?
      if range = @query.filters['range']
        @period = get_date_range(range[:operator].split('_').last, range[:values][:period],range[:values][:from], range[:values][:to])
        @period[:to] ||= Date.today
        @period[:from] ||= Date.today
        @period[:months] = (@period[:to].year*12+@period[:to].month)-(@period[:from].year*12+@period[:from].month) + 1
        @period[:period_type] = range[:operator].split('_').last
        @period[:period] = range[:values][:period]
      else
        @period = Hash.new
      end
    end

    render :partial => 'resalloc' if @fullscreen
  end

  def by_project
    params[:tab] = 'allocations_by_project'
    retrieve_query(EasyUserAllocationByProjectQuery)

    @fullscreen = request.xhr? && params[:fullscreen]

    if @query.valid?
      if range = @query.filters['range']
        @period = get_date_range(range[:operator].split('_').last, range[:values][:period],range[:values][:from], range[:values][:to])
        @period[:to] ||= Date.today
        @period[:from] ||= Date.today
        @period[:months] = (@period[:to].year*12+@period[:to].month)-(@period[:from].year*12+@period[:from].month) + 1
        @period[:period_type] = range[:operator].split('_').last
        @period[:period] = range[:values][:period]
      else
        @period = Hash.new
      end
    end
  end

  def data
    if params[:page_zone_module_uuid]
      epzm = EasyPageZoneModule.find(params[:page_zone_module_uuid])
    elsif params[:page_template_module_uuid]
      epzm = EasyPageTemplateModule.find(params[:page_template_module_uuid])
    end

    if epzm
      @query = EasyUserAllocationQuery.new(:name => '_')
      @query.from_params(epzm.settings)
    else
      retrieve_query(EasyUserAllocationQuery)
    end

    @hide_unassigned_issues = !!params[:hide_unassigned_issues]
    @unassigned_issues = @query.issues(@period[:from], @period[:to]) unless @hide_unassigned_issues
    @users = @query.users
    @allocated_issues_ids = @query.allocated_issues_ids(@period[:from], @period[:to], @users)

    respond_to do |format|
      format.api
    end
  end

  def data_by_project
    retrieve_query(EasyUserAllocationByProjectQuery)
    @data = @query.data_by_project(@period[:from], @period[:to])

    respond_to do |format|
      format.api
    end
  end

  def recalculate
    changed_users = ActiveSupport::JSON.decode(params[:changed_users])
    @recalculated_users = []
    changed_issue_ids = changed_users.collect{|u| u['issues'].keys}.flatten
    changed_users.each do |u|
      user = User.find(u['id'])
      @recalculated_users << [user, user.recalculate_allocations(u['issues'], @period, changed_issue_ids), u['ignoredIssueIds']]
    end
    respond_to do |format|
      format.api
    end
  end

  def save_issues
    errors = []
    unless params[:issues].blank?
      params[:issues].each do |k,v|
        issue = Issue.find(k.to_i)
        if issue
          set_issue_data_from_resalloc(issue, v)
          saved = true
          begin
            saved = issue.save
          rescue ActiveRecord::StaleObjectError
            issue.reload
            set_issue_data_from_resalloc(issue, v)
            saved = issue.save
          end
          if !saved
            errors << l(:notice_failed_to_save_issues2, :issue => '"' + issue.subject + '"', :error =>  issue.errors.full_messages.first)
          elsif !v['customAllocation'].blank? && issue.assigned_to
            custom_allocations = v['customAllocation'].inject({}) {|m, (k,v)| m[Date.parse(k)] = v.to_f; m}
            EasyUserAllocation.allocate_issue!(issue, issue.assigned_to, custom_allocations)
          end
        end
      end
    end
    if errors.any?
      render :json => {:type => 'error', :html => errors.join('<br/>')}
    else
      render :json => {:type => 'notice', :html => l(:notice_successful_update)}
    end
  end

  def save_projects
    errors = []

    if params[:projects]
      params[:projects].each do |project_id, day_shift|
        project = Project.find(project_id)
        project.update_project_entities_dates(day_shift)

        Redmine::Hook.call_hook(:model_project_after_day_shifting, {:project => project})
      end
    end

    if errors.any?
      render :json => {:type => 'error', :html => errors.join('<br/>')}
    else
      render :json => {:type => 'notice', :html => l(:notice_successful_update)}
    end
  end

  def split_issue
    issue = Issue.find(params[:issue_id])
    days = (issue.due_date - issue.start_date).to_i + 1
    begin
      date = params[:date].to_date
    rescue
      date = nil
    end
    unless date.blank?
      ratio = (date - issue.start_date).to_i.to_f / days
      new_issue = issue.copy
      issue.init_journal(User.current)
      issue.due_date = date - 1.day
      issue.estimated_hours = issue.estimated_hours * ratio unless issue.estimated_hours.blank?
      new_issue.start_date = date
      new_issue.estimated_hours = new_issue.estimated_hours - issue.estimated_hours unless issue.estimated_hours.blank?
      issue.save
      new_issue.save
      @issue = new_issue if issue.save && new_issue.save
    end
    respond_to do |format|
      format.api
    end
  end

  private

  def prepare_variables
    params['period_type'] ||= '1'
    params['period'] ||= 'current_month'
    params['from'] ||= Date.today
    params['to'] ||= Date.today + 8.days
  end

  def get_period
    period = get_date_range(params['period_type'], params['period'], params['from'], params['to'])
    period[:all] = params['period'] == 'all'
    period[:from] ||= Date.today
    period[:to] ||= Date.today
    period[:months] = (period[:to].year*12+period[:to].month)-(period[:from].year*12+period[:from].month) + 1
    @period = period
  end

  def set_issue_data_from_resalloc(issue, v)
    issue.init_journal(User.current, v['notes'].to_s)
    issue.start_date = v['start'] unless v['start'].blank?
    issue.due_date = v['end'] unless v['end'].blank?
    issue.start_date = issue.due_date if issue.due_date && issue.due_date < issue.start_date
    issue.assigned_to_id = v['assigned_to_id'] unless v['assigned_to_id'].blank?
    if issue.assigned_to_id && issue.assigned_to_id_changed?
      old_user = User.find_by_id(issue.assigned_to_id_was)
      if old_user && !issue.assigned_to.member_of?(issue.project)
        old_member = old_user.membership(issue.project)
        if old_member
          old_roles = old_member.roles.group(:id).pluck(:id)
          Member.create(:role_ids => old_roles, :user_id => issue.assigned_to_id, :project_id => issue.project_id)
        end
      end
    end
    issue.estimated_hours = v['estimated_hours'] unless v['estimated_hours'].blank?
  end

end
