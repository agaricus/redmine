class EasyRakeTaskCheckFailureTasks < EasyRakeTask

  after_initialize :set_default_settings

  def execute

    failed_tasks = EasyRakeTask.includes(:easy_rake_task_infos).
      where(["#{EasyRakeTaskInfo.table_name}.finished_at BETWEEN ? AND ?", self.day_to_search.beginning_of_day, self.day_to_search.end_of_day]).
      where(["#{EasyRakeTaskInfo.table_name}.status = ?", EasyRakeTaskInfo::STATUS_ENDED_FAILED]).all

    if failed_tasks.size > 0
      EasyMailer.easy_rake_task_check_failure_tasks(self, failed_tasks).deliver
    end

    return true
  end

  def day_to_search
    return @day_to_search if @day_to_search
    if Time.now.hour < 5
      @day_to_search = Date.today - 1.day
    else
      @day_to_search = Date.today
    end
    @day_to_search
  end

  def recepients
    if self.settings['email_type'] == 'email'
      self.settings['email']
    elsif self.settings['email_type'] == 'all_admins'
      User.active.where(:admin => true).where(:id => self.settings['admins']).pluck(:mail)
    end
  end

  private

  def set_default_settings
    self.settings ||= {}
    self.settings['email_type'] ||= 'all_admins'
    if self.settings['email_type'] == 'all_admins' && !self.settings.key?('admins')
      self.settings['admins'] = User.active.where(:admin => true).pluck(:id).collect(&:to_s)
    end
  end

end
