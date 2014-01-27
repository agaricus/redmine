require 'rufus/scheduler'

begin
  require 'EventMachine' unless Object.const_defined?(:EventMachine)
rescue LoadError
  # EventMachine is not available
end


module EasyExtensions

  class EasySchedulerTask

    attr_accessor :name, :options, :in_proc_execution
    attr_accessor :easy_scheduler_task_info

    def initialize(name, options={}, &in_proc_execution)
      @name = name
      @options = options
      @in_proc_execution = in_proc_execution
      @easy_scheduler_task_info = EasySchedulerTaskInfo.create(:name => @name, :status => EasySchedulerTaskInfo::STATUS_INITIALIZED, :page_url_ident => options[:page_url_ident])
    end

    # Override this method to do something else
    def execute
      @in_proc_execution.call unless @in_proc_execution.nil?
    end

    def set_status_planned
      @easy_scheduler_task_info.update_attributes({:status => EasySchedulerTaskInfo::STATUS_PLANNED, :planned_at => DateTime.now})
    end

    def set_status_running
      @easy_scheduler_task_info.update_attributes({:status => EasySchedulerTaskInfo::STATUS_RUNNING, :started_at => DateTime.now})
    end

    def set_status_ended_failed
      @easy_scheduler_task_info.update_attributes({:status => EasySchedulerTaskInfo::STATUS_ENDED_FAILED, :finished_at => DateTime.now})
    end

    def set_status_ended_ok
      @easy_scheduler_task_info.update_attributes({:status => EasySchedulerTaskInfo::STATUS_ENDED_OK, :finished_at => DateTime.now})
    end

    def self.logger
      Rails.logger
    end

    def logger
      self.class.logger
    end

  end

  class EasyScheduler

    private_class_method :new
    @@scheduler, @@scheduler_running = nil, false

    class << self

      def map
        yield self if block_given?
      end

      def logger
        Rails.logger
      end

      # Schedules a task given a cron string.
      #
      # EasyExtensions::EasyScheduler.map do |scheduler|
      #   scheduler.schedule_cron EasyExtensions::EasySchedulerTask.new('order_espresso_task'){puts 'order espresso'}, '35 2 * * *'
      # end
      #
      # will order an espresso in 20 minutes.
      def schedule_cron(task, cron_expresision)
        return unless task.is_a?(EasyExtensions::EasySchedulerTask)

        start_scheduler

        task.set_status_planned

        @@scheduler.schedule cron_expresision, Proc.new{execute_task(task)}
      end

      # Schedules a task in a given amount of time.
      #
      # EasyExtensions::EasyScheduler.map do |scheduler|
      #   scheduler.schedule_in EasyExtensions::EasySchedulerTask.new('order_espresso_task'){puts 'order espresso'}, '20m'
      # end
      #
      # will order an espresso in 20 minutes.
      def schedule_in(task, time)
        return unless task.is_a?(EasyExtensions::EasySchedulerTask)

        start_scheduler

        task.set_status_planned

        @@scheduler.schedule_in time, Proc.new{execute_task(task)}
      end

      # Schedules a task at a given point in time.
      #
      # EasyExtensions::EasyScheduler.map do |scheduler|
      #   scheduler.schedule_at EasyExtensions::EasySchedulerTask.new('order_pizza_task'){puts 'order pizza'}, 'Thu Mar 26 19:30:00 2009'
      # end
      #
      # will order pizza at Thu Mar 26 19:30:00 2009
      def schedule_at(task, time)
        return unless task.is_a?(EasyExtensions::EasySchedulerTask)

        start_scheduler

        task.set_status_planned

        @@scheduler.schedule_at time, Proc.new{execute_task(task)}
      end

      def schedule_every(task, time)
        return unless task.is_a?(EasyExtensions::EasySchedulerTask)

        start_scheduler

        task.set_status_planned

        @@scheduler.schedule_every time, Proc.new{execute_task(task)}
      end

      def start_scheduler
        unless @@scheduler_running
          @@scheduler = nil
          #          if Object.const_defined?(:EventMachine)
          #            EventMachine::run do
          #              @@scheduler = Rufus::Scheduler.start_new
          #            end
          #          else
          #            @@scheduler = Rufus::Scheduler.start_new
          #          end
          @@scheduler = Rufus::Scheduler.new
          @@scheduler_running = true
        end
      end

      def stop_scheduler
        if @@scheduler_running
          @@scheduler.stop
          @@scheduler_running = false
        end
      end

      def scheduler
        @@scheduler
      end

      def execute_task(task)
        begin
          task.set_status_running

          if task.execute
            task.set_status_ended_ok
          else
            task.set_status_ended_failed
          end
        rescue Exception => e
          if logger
            logger.error("execute_task (#{task.name}):#{e.message}")
            logger.error("execute_task (#{task.name}):#{e.backtrace.inspect}")
          end
          task.set_status_ended_failed
        end
      end

    end

  end

end