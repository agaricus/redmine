require 'easy_extensions/scheduler_tasks/git_fetcher_task'

module EasyPatch
  module SysControllerPatch

    def self.included(base)

      base.class_eval do

        def git_fetcher
          task = EasyExtensions::SchedulerTasks::GitFetcherTask.new({:project_id => params[:id]})
          EasyExtensions::EasyScheduler.schedule_in task, '0s'
          render :nothing => true, :status => 200
        end

      end
    end

  end
end
EasyExtensions::PatchManager.register_controller_patch 'SysController', 'EasyPatch::SysControllerPatch'
