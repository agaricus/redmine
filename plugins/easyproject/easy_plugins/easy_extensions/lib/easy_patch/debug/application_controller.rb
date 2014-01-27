ApplicationController.send(:include, EasyExtensions::EasyPerformanceWatcher)

[BulkTimeEntriesController, IssuesController, ProjectsController].each do |klass|
  klass.instance_eval do
    performance_watcher :min_time => 0.05
  end
end