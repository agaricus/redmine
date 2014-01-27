namespace :easyproject do
  namespace :service_tasks do

    desc <<-END_DESC

    Example:
      bundle exec rake easyproject:service_tasks:process_all RAILS_ENV=production --trace
    END_DESC

    task :process_all => [
      :delete_orphans,
      :issues_rebuild,
      :projects_rebuild
    ]

    desc <<-END_DESC
    Runs all data migrations
    END_DESC
    task :data_migrate => :environment do
      name = ENV['NAME']
      version = nil
      version_string = ENV['VERSION']
      if version_string
        if version_string =~ /^\d+$/
          version = version_string.to_i
          if name.nil?
            abort "The VERSION argument requires a plugin NAME."
          end
        else
          abort "Invalid VERSION #{version_string} given."
        end
      end

      begin
        Redmine::Plugin.migrate_easy_data(name, version)
      rescue Redmine::PluginNotFound
        abort "Plugin #{name} was not found."
      end
    end

    desc <<-END_DESC
    Example:
      bundle exec rake easyproject:service_tasks:projects_rebuild RAILS_ENV=production --trace
    END_DESC
    task :projects_rebuild => :environment do
      Project.rebuild!
    end

    desc <<-END_DESC
    Example:
      bundle exec rake easyproject:service_tasks:issues_rebuild RAILS_ENV=production --trace
    END_DESC
    task :issues_rebuild => :environment do
      Issue.rebuild!
    end

    desc <<-END_DESC
    Example:
      bundle exec rake easyproject:service_tasks:delete_orphans RAILS_ENV=production --trace
    END_DESC
    task :delete_orphans => :environment do
      require 'easy_extensions/easyproject_maintenance'
      EasyExtensions::Orphans.delete_all_orphans
    end

    desc <<-END_DESC
    Example:
      bundle exec rake easyproject:service_tasks:clear_cache RAILS_ENV=production --trace
    END_DESC
    task :clear_cache => :environment do
      if File.exist?(ActionController::Base.cache_store.cache_path)
        begin
          ActionController::Base.cache_store.clear
        rescue
          pp "Cache on #{ActionController::Base.cache_store.cache_path} was not deleted. You should do it manually."
        end
      end

    end

    # Translate the language names
    desc <<-END_DESC
    Example:
      bundle exec rake easyproject:service_tasks:invoking_cache RAILS_ENV=production --trace
    END_DESC
    task :invoking_cache => :environment do
      unless ActionController::Base.cache_store.exist? "i18n/languages_options"
        include Redmine::I18n
        languages_options
      end
    end

    desc <<-END_DESC
    Example:
      bundle exec rake easyproject:service_tasks:migrate_to_new_ruby RAILS_ENV=production --trace
    END_DESC
    task :migrate_to_new_ruby => :environment do
      require 'easy_extensions/yaml_encoder'
      y = YamlEncoder.new
      y.repair
    end

  end
end