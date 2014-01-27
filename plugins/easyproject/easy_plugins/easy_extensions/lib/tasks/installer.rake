namespace :easyproject do
  desc <<-END_DESC
    EasyProject installer

    Example:
      bundle exec rake easyproject:install RAILS_ENV=production
  END_DESC

  task :install_with_environment => :environment do
    unless EasyProjectLoader.can_start?
      puts "The Easy Project cannot start because the Redmine is not migrated!"
      puts "Please run `bundle exec rake db:migrate RAILS_ENV=production`"
      puts "and than `bundle exec rake easyproject:install RAILS_ENV=production`"
      exit 1
    end
    puts 'Invoking db:migrate...'
    Rake::Task['db:migrate'].invoke
    puts 'Invoking redmine:plugins:migrate...'
    Rake::Task['redmine:plugins:migrate'].invoke
    puts 'Invoking easyproject:service_tasks:data_migrate...'
    Rake::Task['easyproject:service_tasks:data_migrate'].invoke
    puts 'Invoking redmine:plugins:assets...'
    Rake::Task['redmine:plugins:assets'].invoke
    #    puts 'Invoking easyproject:service_tasks:delete_orphans...'
    #    Rake::Task['easyproject:service_tasks:delete_orphans'].invoke
    puts 'Invoking easyproject:service_tasks:clear_cache...'
    Rake::Task['easyproject:service_tasks:clear_cache'].invoke
    puts 'Invoking easyproject:service_tasks:invoking_cache...'
    Rake::Task['easyproject:service_tasks:invoking_cache'].invoke

    EasyExtensions.additional_installer_rake_tasks.each do |t|
      puts 'Invoking ' + t.to_s
      Rake::Task[t].invoke
    end

  end

  task :install_without_environment do
    puts 'Invoking generate_secret_token...'
    Rake::Task['generate_secret_token'].invoke
    puts 'Invoking change_plugins_order...'
    Rake::Task['easyproject:change_plugins_order'].invoke
    puts 'Invoking clearing session...'
    Rake::Task['tmp:sessions:clear'].invoke
  end

  task :install do
    Rake::Task['easyproject:install_without_environment'].invoke
    Rake::Task['easyproject:install_with_environment'].invoke
  end

end
