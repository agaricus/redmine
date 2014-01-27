class EasyAutoCompletesController < ApplicationController
  helper :issues
  include IssuesHelper

  before_filter :set_self_only

  def parent_issues
    if params[:project_id].blank?
      render_404
      return
    end

    project = Project.find(params[:project_id])
    @issues = get_available_parent_issues(project, params[:term], params[:term].blank? ? nil : 15)

    respond_to do |format|
      format.api
    end
  end

  def my_projects
    @projects = get_visible_projects(params[:term], params[:term].blank? ? nil : 15)

    respond_to do |format|
      format.api { render :template => 'easy_auto_completes/projects_with_url', :formats => [:api]}
    end
  end

  def visible_projects
    @projects = get_visible_projects(params[:term], params[:term].blank? ? nil : 15)

    respond_to do |format|
      format.api { render :template => 'easy_auto_completes/projects_with_id', :formats => [:api]}
    end
  end

  def project_templates
    @projects = get_template_projects(params[:term], params[:term].blank? ? nil : 15)

    respond_to do |format|
      format.api { render :template => 'easy_auto_completes/projects_with_id', :formats => [:api]}
    end
  end

  def add_issue_projects
    @projects = get_visible_projects_with_permission(:add_issues, params[:term], params[:term].blank? ? nil : 15)

    respond_to do |format|
      format.api { render :template => 'easy_auto_completes/projects_with_id', :formats => [:api]}
    end
  end

  def allowed_target_projects_on_move
    @projects = get_visible_projects_with_permission(:move_issues, params[:term], params[:term].blank? ? nil : 15)

    respond_to do |format|
      format.api { render :template => 'easy_auto_completes/projects_with_id', :formats => [:api]}
    end
  end

  def allowed_issue_statuses
    @issue = Issue.find(params[:issue_id])
    render :json => @issue.new_statuses_allowed_to.collect{|s| {:text => s.name, :value => s.id}}
  end

  def issue_priorities
    render :json => IssuePriority.active.collect{|p| {:text => p.name, :value => p.id}}
  end

  def assignable_users
    @issue = Issue.find(params[:issue_id])
    select_options = [['', '']] + assigned_to_collection_for_select_options(@issue)
    render :json => select_options.collect{|o| {:text => o[0], :value => o[1]}}
  end

  def users
    @users = User.active.where(["LOWER(CONCAT(firstname, ' ', lastname)) LIKE ?", "%#{params[:term].downcase}%"]).order('lastname').limit(10).all

    respond_to do |format|
      format.api { render :template => 'easy_auto_completes/users_with_id', :formats => [:api]}
    end
  end

  def internal_users
    @users = User.active.easy_type_internal.where(["LOWER(CONCAT(firstname, ' ', lastname)) LIKE ?", "%#{params[:term].downcase}%"]).order('lastname').limit(10).all

    respond_to do |format|
      format.api { render :template => 'easy_auto_completes/users_with_id', :formats => [:api]}
    end
  end

  def custom_field_possible_values
    cf = CustomField.find(params[:custom_field_id])
    render :json => cf.possible_values.collect{|v| {:text => v, :value => v}}
  end

  private

  def set_self_only
    @self_only = params[:term].blank?
  end

  def get_available_parent_issues(project, term = '', limit = nil)
    if EasySetting.value('show_issue_id', project)
      sql_where = ["#{Issue.table_name}.subject like ? OR #{Issue.table_name}.id = ?", "%#{term}%", term.to_i]
    else
      sql_where = ["#{Issue.table_name}.subject like ?", "%#{term}%"]
    end
    project.issues.visible.where(sql_where).order(:subject).limit(limit).all
  end

  def get_visible_projects_scope(term='', limit=nil)
    scope = Project.visible.non_templates
    scope = scope.where(["#{Project.table_name}.name like ?", "%#{term}%"]).limit(limit).reorder("#{Project.table_name}.lft")
    scope
  end

  def get_template_projects_scope(term='', limit=nil)
    scope = Project.templates
    scope = scope.where(["#{Project.table_name}.name like ?", "%#{term}%"]).limit(limit).reorder("#{Project.table_name}.lft")
  end

  def get_template_projects(term='', limit=nil)
    scope = get_template_projects_scope(term, limit)
    scope.all
  end

  def get_visible_projects(term='', limit=nil)
    scope = get_visible_projects_scope(term, limit)
    scope.all
  end

  def get_visible_projects_with_permission(permission, term='', limit=nil)
    scope = get_visible_projects_scope(term, limit)
    scope = scope.allowed_to(permission)
    scope.all
  end

end
