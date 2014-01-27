ActiveRecord::Base.send(:include, EasyExtensions::EasyPerformanceWatcher)

[Issue, Project, Role, User, EasyQuery, EasyIssueQuery, EasyProjectQuery, EasyUserQuery].each do |klass|
  klass.instance_eval do
    performance_watcher :min_time => 0.05
  end
end