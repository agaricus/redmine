class EasyRakeTaskInfo < ActiveRecord::Base

  STATUS_RUNNING      = 1
  STATUS_ENDED_OK     = 5
  STATUS_ENDED_FAILED = 9

  belongs_to :easy_rake_task
  has_many :easy_rake_task_info_details, :dependent => :destroy

  scope :status_ok, lambda {where(:status => EasyRakeTaskInfo::STATUS_ENDED_OK)}
  scope :status_failed, lambda {where(:status => EasyRakeTaskInfo::STATUS_ENDED_FAILED)}

end
