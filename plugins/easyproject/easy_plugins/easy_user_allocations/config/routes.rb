match '/user_allocation_gantt', :to => 'user_allocation_gantt#index'
match '/projects/:project_id/user_allocation_gantt', :to => 'user_allocation_gantt#index', :as => 'project_allocations'
match '/user_allocation_gantt/data.:format', :to => 'user_allocation_gantt#data'
match '/user_allocation_gantt/data_by_project.:format', :to => 'user_allocation_gantt#data_by_project'
post '/user_allocation_gantt/save_issues', :to => 'user_allocation_gantt#save_issues'
post '/user_allocation_gantt/save_projects', :to => 'user_allocation_gantt#save_projects'
post '/user_allocation_gantt/split_issue.:format', :to => 'user_allocation_gantt#split_issue'
match '/user_allocation_gantt/recalculate.:format', :to => 'user_allocation_gantt#recalculate'

get '/user_allocation_gantt/by_project', :to => 'user_allocation_gantt#by_project'

get 'user_allocation_plan', :to => 'user_allocation_plan#index'
post 'user_allocation_plan/:user_id/save_issue/:issue_id', :to => 'user_allocation_plan#save_issue'
post 'user_allocation_plan/recalculate/:user_id/:issue_id', :to => 'user_allocation_plan#recalculate'
