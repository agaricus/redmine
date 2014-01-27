class EasyRakeTasksController < ApplicationController
  layout 'admin'

  before_filter :find_easy_rake_task, :except => [:index, :new, :create]

  helper :easy_rake_tasks
  include EasyRakeTasksHelper

  def index
    @tasks = EasyRakeTask.all
  end

  def new
    @task = params[:type].constantize.new if params[:type]

    unless @task.is_a?(EasyRakeTask)
      render_404
      return
    end

    @task.safe_attributes = params[:easy_rake_task]

    respond_to do |format|
      format.html
    end
  end

  def create
    @task = params[:type].constantize.new if params[:type]

    unless @task.is_a?(EasyRakeTask)
      render_404
      return
    end

    @task.safe_attributes = params[:easy_rake_task]

    if @task.save
      respond_to do |format|
        format.html  {
          flash[:notice] = l(:notice_successful_create)
          redirect_back_or_default(:action => :index)
        }
      end
    else
      respond_to do |format|
        format.html  { render :action => :new }
      end
    end
  end

  def edit
    respond_to do |format|
      format.html
    end
  end

  def update
    @task.safe_attributes = params[:easy_rake_task]

    if @task.save
      respond_to do |format|
        format.html  {
          flash[:notice] = l(:notice_successful_update)
          redirect_back_or_default(:action => :index)
        }
      end
    else
      respond_to do |format|
        format.html  { render :action => :edit }
      end
    end
  end

  def task_infos
    @task_infos_ok = @task.easy_rake_task_infos.status_ok.limit(10).order("#{EasyRakeTaskInfo.table_name}.started_at DESC").all
    @task_infos_failed = @task.easy_rake_task_infos.status_failed.limit(10).order("#{EasyRakeTaskInfo.table_name}.started_at DESC").all
  end

  def destroy
    if @task.deletable?
      @task.destroy
      flash[:notice] = l(:notice_successful_delete)
    end

    respond_to do |format|
      format.html { redirect_back_or_default :action => 'index' }
    end
  end

  def execute
    #begin
    @task.class.execute_task(@task)
    #rescue
    #end

    redirect_to({:controller => 'easy_rake_tasks', :action => :task_infos, :id => @task, :back_url => params[:back_url]})
  end

  def easy_rake_task_info_detail_receive_mail
    info_detail = EasyRakeTaskInfoDetailReceiveMail.find(params[:easy_task_info_detail_id])
    render :partial => 'easy_rake_tasks/info_detail/easy_rake_task_info_detail_receive_mail', :locals => {:task => @task, :info_detail => info_detail}
  end

  def easy_rake_task_easy_helpdesk_receive_mail_status_detail
    status = params[:status]
    offset = params[:offset].to_i
    limit = 10

    details = EasyRakeTaskInfoDetailReceiveMail.includes(:easy_rake_task_info).where(["#{EasyRakeTaskInfo.table_name}.easy_rake_task_id = ? AND #{EasyRakeTaskInfoDetailReceiveMail.table_name}.status = ?", @task, status]).order("#{EasyRakeTaskInfo.table_name}.finished_at DESC").limit(limit).offset(offset).all

    respond_to do |format|
      format.js { render :partial => 'easy_rake_tasks/additional_task_info/easy_rake_task_easy_helpdesk_receive_mail_status_detail', :locals => {:task => @task, :details => details, :status => status, :offset => offset + limit} }
    end
  end

  private

  def find_easy_rake_task
    @task = EasyRakeTask.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

end
