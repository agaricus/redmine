class EasyRakeTask < ActiveRecord::Base
  include Redmine::SafeAttributes

  has_many :easy_rake_task_infos, :dependent => :destroy

  scope :active, lambda {where(:active => true)}

  acts_as_attachable

  attr_accessor :current_easy_rake_task_info

  serialize :settings, Hash

  safe_attributes 'active', 'settings'
  safe_attributes 'period', 'interval', :if => lambda {|task, user| user.admin? }

  def self.available_periods
    ['monthly', 'daily', 'hourly', 'minutes']
  end

  def self.execute_scheduled(force = false)
    t = Time.now
    log_info "EasyRakeTask::execute_scheduled(force = #{force.to_s}) at #{t}"
    log_info ''

    if !force && EasyRakeTaskInfo.where(["#{EasyRakeTaskInfo.table_name}.status = ? AND #{EasyRakeTaskInfo.table_name}.started_at >= ?", EasyRakeTaskInfo::STATUS_RUNNING, Time.now - 6.hours]).count > 0
      log_info 'Some tasks are still running.'
      return
    end

    started_at = Time.now
    scope = EasyRakeTask.active
    scope = scope.where(["#{EasyRakeTask.table_name}.next_run_at <= ? OR #{EasyRakeTask.table_name}.next_run_at IS NULL", started_at]) unless force

    scope.to_a.each do |task|
      execute_task(task)

      log_info "******************** (#{Time.now - t}s)"
      log_info ''

      task.set_next_run_at(started_at)
    end
  end

  def self.execute_task(task)
    started_at = Time.now
    task.current_easy_rake_task_info = task.easy_rake_task_infos.create(:status => EasyRakeTaskInfo::STATUS_RUNNING, :started_at => started_at)

    begin
      log_info "Starting #{task.caption}"
      status = EasyRakeTaskInfo::STATUS_ENDED_OK

      ret_status = task.execute

      if ret_status == true
        msg = ''
        status = EasyRakeTaskInfo::STATUS_ENDED_OK
      elsif ret_status == false
        msg = ''
        status = EasyRakeTaskInfo::STATUS_ENDED_FAILED
      elsif ret_status.is_a?(Array)
        if ret_status.first == true
          msg = ret_status.second.to_s
          status = EasyRakeTaskInfo::STATUS_ENDED_OK
        else
          msg = ret_status.second.to_s
          status = EasyRakeTaskInfo::STATUS_ENDED_FAILED
        end
      else
        msg = ret_status.to_s
        msg = msg.dup.force_encoding('ascii') if msg.respond_to?(:force_encoding)
        status = EasyRakeTaskInfo::STATUS_ENDED_OK
      end

      task.current_easy_rake_task_info.update_attributes({:status => status, :finished_at => Time.now, :note => msg})
      log_info "END #{task.caption}"
    rescue Exception => ex
      msg = ex.message.to_s
      #msg = msg.dup.force_encoding('ascii') if msg.respond_to?(:force_encoding)
      msg = msg.encode(:invalid => :replace, :replace => '') if msg.respond_to?(:encode)
      task.current_easy_rake_task_info.update_attributes({:status => EasyRakeTaskInfo::STATUS_ENDED_FAILED, :finished_at => Time.now, :note => msg})
      log_info "ERROR #{task.caption} - #{msg}"
      log_info ex.backtrace.join("\n")
    end
  end

  def self.log_info(msg = '')
    STDOUT.puts(msg.to_s) if STDOUT
    if EasyRakeTask.logger
      if msg.is_a?(Array)
        EasyRakeTask.logger.info(msg.join("\n"))
      else
        EasyRakeTask.logger.info(msg.to_s)
      end
    end
  end

  def log_info(msg = '')
    self.class.log_info(msg)
  end

  def self.logger
    @@easy_rake_tasks_logger ||= Logger.new(File.join(Rails.root, 'log', 'easy_rake_tasks.log'), 'weekly')
  end

  #To override
  def info_detail_status_caption(status)
    'unknown'
  end

  def caption
    l(:"easy_rake_tasks.#{self.class.name.underscore}.caption")
  end

  def execute
    raise NotImplementedError
  end

  def set_next_run_at(last_time = nil)
    self.update_attribute(:next_run_at, calculate_next_run(last_time))
  end

  def settings_view_path
    "easy_rake_tasks/settings/#{self.class.name.underscore}"
  end

  def additional_task_info_view_path
    'common/empty'
  end

  def deletable?
    builtin == 0
  end

  def project
    nil # attachment workaround
  end

  def attachments_visible?(user)(user=User.current)
    true  # attachment workaround
  end

  private

  def calculate_next_run(last_time = nil)
    last_time ||= Time.now

    case self.period.to_sym
    when :monthly
      return last_time + self.interval.months
    when :daily
      return last_time + self.interval.days
    when :hourly
      return last_time + self.interval.hours
    when :minutes
      return last_time + self.interval.minutes
    end
  end

end
