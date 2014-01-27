class EasyMoneyPrioritiesController < ApplicationController

  before_filter :find_project_by_project_id, :only => [:update_priorities_to_subprojects]
  before_filter :require_admin, :only => [:update_priorities_to_projects]
  before_filter :my_authorize, :only => [:update_priorities_to_subprojects]  
 
  helper :easy_money
  include EasyMoneyHelper

  def update_priorities_to_projects
    default_priorities = EasyMoneyRatePriority.rate_priorities_by_project(nil)
    Project.non_templates.has_module(:easy_money).each do |project|
      update_project_priorities(project, default_priorities)
    end

    if request.xhr?
      render :nothing => true
    else
      flash[:notice] = l(:notice_successful_update)
      redirect_back_or_default({:controller => 'easy_money_settings', :action => 'index', :tab => 'EasyMoneyRatePriority'})
    end
  end

  def update_priorities_to_subprojects
    default_priorities = EasyMoneyRatePriority.rate_priorities_by_project(@project)
    @project.descendants.active.has_module(:easy_money).each do |project|
      update_project_priorities(project, default_priorities)
    end

    if request.xhr?
      render :nothing => true
    else
      flash[:notice] = l(:notice_successful_update)
      redirect_back_or_default({:controller => 'easy_money_settings', :action => 'project_settings', :project_id => @project, :tab => 'EasyMoneyRatePriority'})
    end
  end
  
  private

  def my_authorize
    unless @project.nil?
      authorize
    end
  end

  def find_project_by_project_id
    @project = Project.find(params[:project_id]) if params[:project_id]
  end

  def update_project_priorities(project, default_priorities)
    project_priorities = EasyMoneyRatePriority.rate_priorities_by_project(project)
    default_priorities.each do |default_priority|
      if project_priorities
        project_priority = project_priorities.find(:first, :conditions => {:rate_type_id => default_priority.rate_type_id, :entity_type => default_priority.entity_type})
        if project_priority
          update_priority(project_priority, default_priority)
        else
          create_priority(project, default_priority)
        end
      else
        create_priority(project, default_priority)
      end
      
    end
  end

  def create_priority(project, default_priority)
    EasyMoneyRatePriority.create(:project_id => project.id, :rate_type_id => default_priority.rate_type_id, :entity_type => default_priority.entity_type, :position => default_priority.position)
  end

  def update_priority(project_priority, default_priority)
    project_priority.position = default_priority.position
    project_priority.save
  end

end
