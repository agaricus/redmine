class TemplatesController < ApplicationController
  layout 'admin'

  before_filter :authorize_global, :only => [:destroy, :bulk_destroy]
  before_filter :find_source_project, :except => [:index, :bulk_destroy]

  helper :custom_fields
  include CustomFieldsHelper
  helper :projects
  include ProjectsHelper
  helper :entity_attribute
  include EntityAttributeHelper

  accept_api_auth :index, :restore, :add, :make_project_from_template, :copy_project_from_template, :destroy

  # Lists visible projects
  def index
    @projects = Project.templates.reorder('lft').all

    respond_to do |format|
      format.html
      format.api
    end
  end

  # Restores template to the original project
  def restore
    @source_project.to_projects!

    respond_to do |format|
      format.html {
        flash[:notice] = l(:notice_successful_restore_template)
        redirect_to :controller => 'templates', :action => 'index'
      }
      format.api  { render_api_ok }
    end
  end

  # Creates a template from the project
  def add
    unsaved_template = nil

    Mailer.with_deliveries(false) do
      unsaved_template = @source_project.create_project_templates(:copying_action => :creating_template)
    end

    respond_to do |format|
      if unsaved_template
        err_msg = (l(:error_can_not_create_project_template, :projectname => ERB::Util.html_escape(unsaved_template.name)) + '<br/>' + unsaved_template.errors.full_messages.join('<br />')).html_safe
        format.html {
          flash[:error] = err_msg
          redirect_back_or_default({:controller => 'projects', :action => 'settings', :id => @source_project})
        }
        format.api  { render_api_error(err_msg) }
      else
        format.html {
          flash[:notice] = l(:notice_successful_create_template)
          redirect_to :controller => 'templates', :action => 'index'
        }
        format.api  { render_api_ok }
      end
    end
  end

  # Shows form to create project from template
  def show_create_project
    @projects = @source_project.self_and_descendants
    @projects.delete_if {|projects| projects.status == Project::STATUS_ARCHIVED}
    @projects.each{|p| p.reinitialize_values}

    respond_to do |format|
      format.html { render :template => 'templates/create' }
    end

  end

  # Shows form to create project from template
  def show_copy_project
    @projects = @source_project.self_and_descendants
    @projects.delete_if {|projects| projects.status == Project::STATUS_ARCHIVED}
    @projects.each{|p| p.reinitialize_values}

    respond_to do |format|
      format.html { render :template => 'templates/copy' }
    end

  end

  # Creates a project from the template
  def make_project_from_template
    @new_project, saved_projects, unsaved_projects = nil

    Mailer.with_deliveries(false) do
      @new_project, saved_projects, unsaved_projects = @source_project.project_with_subprojects_from_template(params[:template][:parent_id], params[:template][:project], {:copying_action => :creating_project}) if params[:template] && params[:template][:parent_id]
    end

    if !@new_project.nil? && @new_project.valid?
      shifted_projects = []
      if params[:template] && params[:template][:update_dates] && params[:template][:start_date]
        new_start_date = params[:template][:start_date].to_date
        saved_projects.each do |project|
          next unless project.start_date

          day_shift = (new_start_date - project.start_date).to_i
          project.update_project_entities_dates(day_shift)

          shifted_projects << project
        end if new_start_date.is_a?(Date)
      end

      if params[:template] && params[:template][:match_starting_dates]
        saved_projects.each do |project|
          match_starting_dates(project)

          shifted_projects << project unless shifted_projects.include?(project)
        end
      end

      if params[:template] && !params[:template][:change_issues_author].blank?
        Issue.update_all(['author_id = ?', params[:template][:change_issues_author]], "project_id IN (#{saved_projects.collect(&:id).join(',')})")
      end

      shifted_projects.each do |p|
        Redmine::Hook.call_hook(:model_project_after_day_shifting, {:project => p})
      end

      Redmine::Hook.call_hook(:controller_templates_create_project_from_template, {:source_project => @source_project, :params => params, :saved_projects => saved_projects, :unsaved_projects => unsaved_projects})
    end

    respond_to do |format|

      if @new_project.nil? || !@new_project.valid?
        if @new_project.nil?
          err_msg = l(:notice_failed_create_project_from_template, :errors => 'Missing required fields')
        else
          err_msg = l(:notice_failed_create_project_from_template, :errors => @new_project.errors.full_messages.join(','))
        end
        flash[:error] = err_msg
        format.html { redirect_to( :controller => 'templates', :action => 'show_create_project', :id => @source_project ) }
        format.api { render_api_error(err_msg) }
      else
        flash[:notice] = l(:notice_successful_create_project_from_template)
        format.html { redirect_to( :controller => 'projects', :action => 'settings', :id => @new_project ) }
        format.api {
          @project = @new_project
          render :template => 'projects/show', :status => :created, :location => url_for(:controller => 'projects', :action => 'show', :id => @project.id)
        }
      end

    end
  end

  def copy_project_from_template
    if params[:template]
      target_root_project = Project.where(:id => params[:template][:target_root_project_id]).first if params[:template][:target_root_project_id]

      unless target_root_project
        flash[:error] = l(:error_project_not_selected)

        respond_to do |format|
          format.html {
            redirect_to( :controller => 'templates', :action => 'show_copy_project', :id => @source_project )
          }
          format.api {
            err_msg = l(:notice_failed_create_project_from_template, :errors => 'Missing required fields')
            render_api_error(err_msg)
          }
        end
        return
      end

      if target_root_project
        Mailer.with_deliveries(false) do
          target_root_project.delete_easy_page_modules
          target_root_project.copy(@source_project, {})
        end

        saved_projects = [target_root_project]
      end

      if !target_root_project.nil? && target_root_project.valid?
        shifted_projects = []
        if params[:template][:update_dates] && params[:template][:start_date]
          new_start_date = params[:template][:start_date].to_date
          saved_projects.each do |project|
            next unless project.start_date

            day_shift = (new_start_date - project.start_date).to_i
            project.update_project_entities_dates(day_shift)

            shifted_projects << project
          end
        end

        if params[:template][:match_starting_dates]
          saved_projects.each do |project|
            match_starting_dates(project)

            shifted_projects << project unless shifted_projects.include?(project)
          end
        end

        if !params[:template][:change_issues_author].blank?
          Issue.update_all(['author_id = ?', params[:template][:change_issues_author]], "project_id IN (#{saved_projects.collect(&:id).join(',')})")
        end

        shifted_projects.each do |p|
          Redmine::Hook.call_hook(:model_project_after_day_shifting, {:project => p})
        end
      end
    end
    respond_to do |format|

      if target_root_project.nil? || !target_root_project.valid?
        if target_root_project.nil?
          err_msg = l(:notice_failed_create_project_from_template, :errors => 'Missing required fields')
        else
          err_msg = l(:notice_failed_create_project_from_template, :errors => target_root_project.errors.full_messages.join(','))
        end
        flash[:error] = err_msg
        format.html { redirect_to( :controller => 'templates', :action => 'show_copy_project', :id => @source_project ) }
        format.api { render_api_error(err_msg) }
      else
        flash[:notice] = l(:notice_successful_create_project_from_template)
        format.html { redirect_to( :controller => 'projects', :action => 'settings', :id => target_root_project ) }
        format.api {
          @project = @new_project
          render :template => 'projects/show', :status => :created, :location => url_for(:controller => 'projects', :action => 'show', :id => @project.id)
        }
      end

    end
  end

  def destroy
    @source_project.destroy
    flash[:notice] = l(:notice_successful_delete)
    redirect_to :controller => 'templates', :action => 'index'
  rescue
    flash[:error] = l(:error_can_not_delete_project_template)
    redirect_to :controller => 'templates', :action => 'index'
  end

  def bulk_destroy
    Project.where(:id => params[:ids]).destroy_all
    flash[:notice] = l(:notice_successful_delete)
    redirect_to :controller => 'templates', :action => 'index'
  rescue
    flash[:error] = l(:error_can_not_delete_project_template)
    redirect_to :controller => 'templates', :action => 'index'
  end

  private

  def find_source_project
    @source_project = Project.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def match_starting_dates(project)
    return unless project
    date = project.easy_start_date
    return if date.blank?

    Issue.update_all(['start_date = ?', date], ['project_id = ?', project.id])
  end

end
