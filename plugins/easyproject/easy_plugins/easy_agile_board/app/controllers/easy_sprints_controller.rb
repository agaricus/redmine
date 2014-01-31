class EasySprintsController < ApplicationController
  before_filter :force_xhr
  before_filter :find_easy_sprint
  before_filter :find_project
  before_filter :authorize

  helper :issues

  def new
    @easy_sprint = EasySprint.new
    @easy_sprint.project = @project
    render :layout => false
  end

  def create
    @easy_sprint = EasySprint.new
    @easy_sprint.safe_attributes = params[:easy_sprint]
    @easy_sprint.project = @project

    if @easy_sprint.save
      respond_to do |format|
        format.api { render_api_ok }
      end
    else
      respond_to do |format|
        format.api { render_validation_errors @easy_sprint }
      end
    end
  end

  def show
  end

  def index
    @sprints = @project.easy_sprints.preload(:issue_easy_sprint_relations => :issue).all
    render :layout => false
  end

  def edit
    render layout: false
  end

  def update
    @easy_sprint.safe_attributes = params[:easy_sprint]
    if @easy_sprint.save
      respond_to do |format|
        format.api { render_api_ok }
      end
    else
      respond_to do |format|
        format.api { render_validation_errors @easy_sprint }
      end
    end
  end

  def destroy
    @easy_sprint.destroy
    respond_to do |format|
      format.js
    end
  end

  def assign_issue
    issue = Issue.find(params[:issue_id])
    @easy_sprint.assign_issue(issue, params[:relation_type])
    render_api_ok
  end

  def unassign_issue
    IssueEasySprintRelation.where(:issue_id => params[:issue_id]).destroy_all
    render_api_ok
  end

  private

  def force_xhr
    render_404 unless request.xhr?
  end

  def find_easy_sprint
    @easy_sprint = EasySprint.find(params[:id]) if params[:id]
  end

  def find_project
    @project = Project.find(params[:project_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
