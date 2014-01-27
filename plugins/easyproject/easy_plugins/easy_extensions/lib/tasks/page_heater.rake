namespace :easyproject do
  namespace :scheduler_tasks do

    desc <<-END_DESC
    Clears tha page's fragment cache anh hits defined pages to refresh cache

    Example:
      bundle exec rake easyproject:scheduler_tasks:page_heater RAILS_ENV=production
    END_DESC

    task :page_heater => :environment do
      if EasySetting.value('use_easy_cache') || ENV.key?('force')
        Rails.logger.auto_flushing = true
        heater_task = EasyExtensions::EasyProjectHeaterSchedulerTask.new
        heater_task.execute
      end
    end

    task :clear_cache => :environment do
      FileUtils.rm Dir[ActionController::Base.cache_store.cache_path + '/views/*.cache']
    end

  end
end