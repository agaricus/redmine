require 'easy_money/scheduler_tasks/ep_update_projects_time_entry_expenses'

class EasyMoneyTimeEntryExpensesController < ApplicationController

  menu_item :easy_money

  before_filter :find_easy_money_project, :only => [:index, :update_project_time_entry_expenses, :update_project_and_subprojects_time_entry_expenses]
  before_filter :authorize, :only => [:index, :update_project_time_entry_expenses, :update_project_and_subprojects_time_entry_expenses]
  before_filter :require_admin, :only => [:update_all_projects_time_entry_expenses]


  helper :custom_fields
  include CustomFieldsHelper
  helper :easy_money
  include EasyMoneyHelper
  helper :attachments
  include AttachmentsHelper
  helper :sort
  include SortHelper

  def index
    sort_init 'project', 'asc'
    sort_update 'project' => "#{Project.table_name}.name", 'subject' => "#{Issue.table_name}.subject"

    case params[:format]
    when 'csv', 'pdf'
      @limit = Setting.issues_export_limit.to_i
    when 'atom'
      @limit = Setting.feeds_limit.to_i
    when 'xml', 'json'
      @offset, @limit = api_offset_and_limit
    else
      @limit = per_page_option
    end

    cond = []
    cond << "#{Project.table_name}.id = " + @project.id.to_s

    #also comute archived
    @project.self_and_descendants.has_module(:easy_money).each do |child|
      cond << "#{Project.table_name}.id = " + child.id.to_s
    end if @project.easy_money_settings.include_childs?

    project_conditions = '(' + cond.join(' OR ') +  ") AND #{TimeEntry.table_name}.issue_id IS NULL"
    issue_conditions = '(' + cond.join(' OR ') +  ") AND #{TimeEntry.table_name}.hours > 0"

    @project_time_entries = TimeEntry.where(project_conditions).includes(:easy_money_time_entry_expenses).joins(:project).order('user_id, spent_on').all

    issue_scope = Issue.where(issue_conditions).includes(:easy_money_time_entry_expenses).joins(:project)

    @issues_count = issue_scope.count
    @issues_pages = Redmine::Pagination::Paginator.new @issues_count, @limit, params['page']
    @offset ||= @issues_pages.offset
    @issues = issue_scope.order(sort_clause).offset(@offset).limit(@limit)
    
    respond_to do |format|
      format.html { request.xhr? ? render(:partial => 'issue_time_entry', :locals => { :url_params => { :project_id => @project } }) : render(:action => 'index', :layout => !request.xhr?) }
      format.csv  { send_data(easy_money_time_entries_to_csv(@project_time_entries, @issues, @project.easy_money_settings)) }
    end
  end

  def update_project_time_entry_expenses
    running_scheduler_task_info = EasySchedulerTaskInfo.find_unfinished('update_project_time_entry_expenses')
    unless running_scheduler_task_info
      update_projects_time_entry_expenses(EasyExtensions::EpUpdateProjectsTimeEntryExpenses.new(@project.id), params[:back_url])
    else
      respond_to do |format|
        format.js{@task_info = running_scheduler_task_info; render :action => 'update_all_projects_time_entry_expenses'}
      end
    end
  end

  def update_project_and_subprojects_time_entry_expenses
    running_scheduler_task_info = EasySchedulerTaskInfo.find_unfinished('update_project_time_entry_expenses')
    unless running_scheduler_task_info
      update_projects_time_entry_expenses(EasyExtensions::EpUpdateProjectsTimeEntryExpenses.new(@project.self_and_descendants.active.has_module(:easy_money).pluck(:id)), params[:back_url])
    else
      respond_to do |format|
        format.js{@task_info = running_scheduler_task_info;render :action => 'update_all_projects_time_entry_expenses'}
      end
    end
  end

  def update_all_projects_time_entry_expenses
    running_scheduler_task_info = EasySchedulerTaskInfo.find_unfinished('update_project_time_entry_expenses')
    unless running_scheduler_task_info
      update_projects_time_entry_expenses(EasyExtensions::EpUpdateProjectsTimeEntryExpenses.new, params[:back_url])
    else
      respond_to do |format|
        format.js{@task_info = running_scheduler_task_info}
      end
    end
  end  
  
  private

  def update_projects_time_entry_expenses(task, back_url)
    EasyExtensions::EasyScheduler.schedule_in task, '0s'

    respond_to do |format|
      format.js{@task_info = task.easy_scheduler_task_info; render :action => 'update_all_projects_time_entry_expenses'}
    end
  end
  
end