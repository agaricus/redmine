module EasyRakeTasksHelper

  def task_period_caption(task)
    l(:"easy_rake_tasks.periods.#{task.period}", :interval =>  task.interval)
  end

  def task_info_status(task_info)
    case task_info.status
    when EasyRakeTaskInfo::STATUS_RUNNING
      l(:'easy_rake_task_infos.status.running')
    when EasyRakeTaskInfo::STATUS_ENDED_OK
      l(:'easy_rake_task_infos.status.ended_ok')
    when EasyRakeTaskInfo::STATUS_ENDED_FAILED
      l(:'easy_rake_task_infos.status.ended_failed')
    end
  end

end