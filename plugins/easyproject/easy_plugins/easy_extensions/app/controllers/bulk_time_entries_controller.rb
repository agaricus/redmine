# encoding: utf-8
class BulkTimeEntriesController < ApplicationController

  before_filter :authorize_global
  before_filter :find_user
  before_filter :check_for_no_projects, :only => [:index]
  before_filter :get_top_last_entries, :only => [:index]
  before_filter :get_time_entry, :only => [:index, :load_assigned_issues, :save, :load_fixed_activities]

  helper :custom_fields
  include BulkTimeEntriesHelper
  helper :issues
  include IssuesHelper
  helper :timelog
  include TimelogHelper
  helper :entity_attribute
  include EntityAttributeHelper
  helper :easy_query
  include EasyQueryHelper
  helper :easy_attendances
  include EasyAttendancesHelper

  def index
    limit = EasySetting.value('easy_select_limit')
    @users = get_users if count_users < limit || in_mobile_view?
    @projects = get_projects if count_projects < limit || in_mobile_view?
    @issues = get_issues if (count_issues < limit || in_mobile_view?) && @time_entry.project
  end

  def load_users
    respond_to do |format|
      format.json {
        if User.current.admin?
          @users = get_users
          unless params[:term].blank?
            @users = @users.select{|u| u.name.match(/#{Regexp.escape(params[:term])}/i)}
          end
        else
          @users = []
        end
        render :json => @users.collect{|u| {:value => u.name, :id => u.id}}
      }
    end
  end

  def load_assigned_projects
    respond_to do |format|
      format.json {
        @projects = get_projects(params[:term], params[:term].blank? ? 100 : 15)
        projects_data = []
        Project.each_with_easy_level(@projects) do |project, level|
          projects_data << {:value => project.family_name(:level => level, :separator => "\302\240\302\273\302\240", :prefix => "\302\240", :self_only => true), :id => project.id}
        end
        render :json => projects_data
      }
    end
  end

  def load_assigned_issues
    respond_to do |format|
      format.json {
        @issues = get_issues(params[:term], params[:term].blank? ? 100 : 15)
        render :json => @issues.collect{|i| {:value => i.to_s, :id => i.id}}
      }
    end
  end

  def load_fixed_activities
    render :partial => 'timelog/user_time_entry', :locals => {:required => true,
      :tag_name_prefix => 'time_entry',
      :time_entry => @time_entry,
      :activities => @activity_collection,
      :project => @time_entry.project, :issue => @time_entry.issue}
  end

  def save
    new_params = {}
    new_params[:page_module_uuid] = params[:page_module_uuid] if params[:page_module_uuid]
    new_params[:spent_on] = params[:spent_on] if params[:spent_on]
    new_params[:back_url] = params[:back_url] if params[:back_url]

    if @time_entry.project && @time_entry.project.fixed_activity? && @time_entry.activity_id.blank?
      @time_entry.activity_id = @time_entry.issue.activity_id if @time_entry.issue
    end

    if @time_entry.save
      if params[:continue]
        flash[:notice] = l(:notice_successful_create)
        redirect_to :action => 'index', :spent_on => @time_entry.spent_on, :params => new_params
      end
    else
      get_top_last_entries
      render :action => 'index'
    end
  end

  private

  def find_user
    begin
      @user = User.find(params[:user_id]) if User.current.admin? && !params[:user_id].blank?
    rescue
    end
    @user ||= User.current
  end

  def get_last_project
    time_entry = TimeEntry.includes(:project).where(Project.allowed_to_condition(@user, :log_time)).where(["#{TimeEntry.table_name}.user_id = ?", @user.id]).reorder("#{TimeEntry.table_name}.id DESC").first
    last_project ||= time_entry.project if time_entry

    last_project ||= get_projects('', nil, :only_one => true).first
  end

  def get_last_issue
    if params[:issue_id]
      last_issue = Issue.find(params[:issue_id])
    elsif params[:action] != 'save' && @time_entry && @time_entry.issue
      last_issue = @time_entry.issue
    else
      last_issue = @issues ? @issues.first : nil
    end
    last_issue
  end

  def get_time_entry
    begin
      spent_on = Date.parse(params[:spent_on])
    rescue
      spent_on = User.current.today
    end

    if params[:time_entry_id]
      @time_entry = TimeEntry.find(params[:time_entry_id])
      @time_entry.spent_on = spent_on if params[:spent_on]
      @time_entry.user = @user if !params[:user_id].blank? && User.current.admin?
    else
      @time_entry = TimeEntry.new(:spent_on => spent_on, :user => @user)
    end

    if @time_entry.new_record? && (params[:project_id].blank? || params[:user_changed])
      @time_entry.project = get_last_project
    elsif !params[:project_id].blank? && (project = Project.find(params[:project_id])) && @user.allowed_to?(:log_time, project)
      @time_entry.project = project
    end

    if params[:time_entry]
      @time_entry.safe_attributes = params[:time_entry]
    end

    if (params[:user_changed] || params[:project_changed])
      @time_entry.issue_id = nil
    else
      @time_entry.issue_id = params[:issue_id] if params[:issue_id]
    end

    if @time_entry.project.blank?
      @activity_collection = []
    else
      # params["user_role_id_time_entry"] ||= @time_entry.user.roles_for_project(@time_entry.project).first.id.to_s
      @activity_collection = activity_collection(@time_entry.user, params["user_role_id_time_entry"], @time_entry.project)
    end
  end

  def get_users
    if User.current.admin?
      User.active.non_system_flag.easy_type_internal.sorted
    else
      []
    end
  end

  def count_users
    if User.current.admin?
      User.active.non_system_flag.easy_type_internal.count
    else
      0
    end
  end

  def get_projects_scope
    if @user.blank?
      nil
    elsif @user.admin?
      Project.active.has_module(:time_tracking)
    else
      @user.projects.active.where(Project.allowed_to_condition(@user, :log_time))
    end
  end

  def get_projects(term='', limit=nil, options={})
    scope = get_projects_scope
    if scope
      scope = scope.where(["#{Project.table_name}.name like ?", "%#{term}%"]).limit(limit).reorder("#{Project.table_name}.lft")
      options[:only_one] ? [scope.first] : scope.all
    else
      []
    end
  end

  def count_projects
    scope = get_projects_scope
    if scope
      @project_count ||= scope.count
    else
      @project_count ||= 0
    end
  end

  def get_issues_scope
    if !@time_entry.nil? && !@time_entry.project.nil?
      scope = Issue.visible(@user).includes(:project).where(Project.allowed_to_condition(@user, :log_time, :project => @time_entry.project)).order("#{Issue.table_name}.subject")
      scope = scope.includes(:status).where(IssueStatus.table_name => {:is_closed => false}) unless EasySetting.value('allow_log_time_to_closed_issue')
      scope = scope.select([:id, :subject])
    else
      nil
    end
  end

  def get_issues(term='', limit=nil, options={})
    scope = get_issues_scope
    if scope
      scope = scope.where(["#{Issue.table_name}.subject like ?", "%#{term}%"]).limit(limit)
      options[:only_one] ? [scope.first] : scope.all
    else
      []
    end
  end

  def count_issues
    scope = get_issues_scope
    if scope
      @issues_count ||= scope.count
    else
      @issues_count ||= 0
    end
  end

  def find_project
    @selected_project = Project.find(params[:project_id]) unless params[:project_id].blank?
    time_entry = TimeEntry.find(:first, :conditions => "#{TimeEntry.table_name}.user_id = #{@user.id} AND " + Project.allowed_to_condition(@user, :log_time), :include => :project, :order => "#{TimeEntry.table_name}.id DESC", :limit => 1)
    @selected_project ||= time_entry.project if time_entry
    @selected_project ||= Project.visible.has_module(:time_tracking).first
  end

  def check_for_no_projects
    if count_projects == 0 && request.xhr?
      render :action => 'no_projects', :format => :js
      return false
    end
  end

  def get_top_last_entries
    if !params[:user_changed].blank? || !request.xhr?
      @top_last_entries = Project.visible(@user).has_module(:time_tracking).
        select("#{Project.table_name}.id, #{Project.table_name}.name").
        where(["#{TimeEntry.table_name}.user_id = ?", @user.id]).
        joins(:time_entries).
        group("#{Project.table_name}.id, #{Project.table_name}.name").
        reorder("MAX(#{TimeEntry.table_name}.created_on) DESC").
        limit(10).all
    else
      @top_last_entries = []
    end
  end

end
