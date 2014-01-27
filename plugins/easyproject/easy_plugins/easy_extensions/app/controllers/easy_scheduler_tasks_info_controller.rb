class EasySchedulerTasksInfoController < ApplicationController

  before_filter :find_task, :only => :task_info

  def task_info
    if @scheduler_task_info.status == EasySchedulerTaskInfo::STATUS_INITIALIZED
      render :partial => 'easy_scheduler_tasks_info/initialized', :locals => { :scheduler_task_info => @scheduler_task_info, :back_url => params[:back_url] }
    elsif @scheduler_task_info.status == EasySchedulerTaskInfo::STATUS_PLANNED
      render :partial => 'easy_scheduler_tasks_info/planned', :locals => { :scheduler_task_info => @scheduler_task_info, :back_url => params[:back_url] }
    elsif @scheduler_task_info.status == EasySchedulerTaskInfo::STATUS_RUNNING
      render :partial => 'easy_scheduler_tasks_info/running', :locals => { :scheduler_task_info => @scheduler_task_info, :back_url => params[:back_url] }
    elsif @scheduler_task_info.status == EasySchedulerTaskInfo::STATUS_ENDED_FAILED
      render :partial => 'easy_scheduler_tasks_info/ended_failed', :locals => { :scheduler_task_info => @scheduler_task_info, :back_url => params[:back_url] }
    elsif @scheduler_task_info.status == EasySchedulerTaskInfo::STATUS_ENDED_OK
      render :partial => 'easy_scheduler_tasks_info/ended_ok', :locals => { :scheduler_task_info => @scheduler_task_info, :back_url => params[:back_url] }
    else
      render :nothing => true
    end
  end

  private

  def find_task
    @scheduler_task_info = EasySchedulerTaskInfo.find(params[:task_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

end