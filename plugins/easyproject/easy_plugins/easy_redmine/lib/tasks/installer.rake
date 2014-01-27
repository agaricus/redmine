namespace :easyredmine do
  desc <<-END_DESC
    Easy Redmine installer

    Example:
      bundle exec rake easyredmine:install RAILS_ENV=production
  END_DESC

  task :install do
    Rake::Task['easyproject:install'].invoke
  end

end