namespace :easyproject do
  namespace :scheduler do

    desc <<-END_DESC

    Example:
      bundle exec rake easyproject:scheduler:run_tasks RAILS_ENV=production
      bundle exec rake easyproject:scheduler:run_tasks force=true RAILS_ENV=production
    END_DESC

    task :run_tasks => :environment do

      force = !!ENV.delete('force')
      EasyRakeTask.execute_scheduled(force)

    end

  end
end