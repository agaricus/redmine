class EasyRakeTaskHistoryCleaner < EasyRakeTask

  def execute

    time_to_delete = Time.now - 2.week

    EasyRakeTaskInfo.where(["#{EasyRakeTaskInfo.table_name}.status <> ?", EasyRakeTaskInfo::STATUS_RUNNING]).
      where(["#{EasyRakeTaskInfo.table_name}.finished_at < ?", time_to_delete]).destroy_all

    Attachment.where(["#{Attachment.table_name}.container_type = ? AND #{Attachment.table_name}.created_on < ?", 'EasyRakeTask', time_to_delete]).destroy_all

    return true
  end

end
