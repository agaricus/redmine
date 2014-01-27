require 'easy_extensions/easy_scheduler'

module EasyExtensions
  module SchedulerTasks

    class GitFetcherTask < EasyExtensions::EasySchedulerTask

      def initialize(options={})
        super('git_fetcher_task', options)
      end

      def execute
        logger.info 'GitFetcherTask excuting...' if logger

        projects = []
        if options[:project_id]
          projects << Project.active.non_templates.has_module(:repository).find(options[:project_id])
        else
          projects = Project.active.non_templates.has_module(:repository).find(:all, :include => :repository)
        end
        projects.each do |project|
          if project.repository
            logger.info "GitFetcherTask fetching #{project.repository.url}" if logger

            system "cd #{project.repository.url} && git fetch"
            project.repository.fetch_changesets
          end
        end

        logger.info 'GitFetcherTask excuted.' if logger
      end

    end
 
  end
end