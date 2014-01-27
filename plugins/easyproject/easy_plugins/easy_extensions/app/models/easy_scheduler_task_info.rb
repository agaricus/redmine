class EasySchedulerTaskInfo < ActiveRecord::Base
  self.table_name = 'easy_scheduler_tasks'

  STATUS_INITIALIZED  = 1
  STATUS_PLANNED      = 2
  STATUS_RUNNING      = 3
  STATUS_ENDED_FAILED = 4
  STATUS_ENDED_OK     = 5

  def self.find_unfinished(page_url_ident = nil)
    find(:first, :conditions => {:page_url_ident => page_url_ident, :status => [STATUS_INITIALIZED, STATUS_PLANNED, STATUS_RUNNING]})
  end

end

