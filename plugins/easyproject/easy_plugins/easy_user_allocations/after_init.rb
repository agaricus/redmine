ActiveRecord::Base.observers += [:easy_user_allocation_observer]

Dir[File.dirname(__FILE__) + '/lib/easy_user_allocations/easy_extensions/controllers/*.rb'].each {|file| require_dependency file }
Dir[File.dirname(__FILE__) + '/lib/easy_user_allocations/redmine/controllers/*.rb'].each {|file| require_dependency file }
Dir[File.dirname(__FILE__) + '/lib/easy_user_allocations/redmine/models/*.rb'].each {|file| require_dependency file }

ActionDispatch::Reloader.to_prepare do
  Redmine::AccessControl.map do |map|
    map.project_module :easy_user_allocations do |pmap|
      pmap.permission :view_easy_user_allocations, {:user_allocation_gantt => [:index, :data, :recalculate]}, :read => true
      pmap.permission :view_my_easy_user_allocations, {:user_allocation_gantt => [:index, :data, :recalculate], :user_allocation_plan => [:index, :recalculate]}, :read => true
      pmap.permission :edit_easy_user_allocations, {:user_allocation_gantt => [:save_issues, :split_issue], :user_allocation_plan => [:save_issue]}
      pmap.permission :view_easy_user_allocations_by_project, {:user_allocation_gantt => [:index, :by_project, :data_by_project, :save_projects]}
    end
  end

  Redmine::MenuManager.map :top_menu do |menu|
    menu.push :user_allocations, {:controller => 'user_allocation_gantt', :action => 'index', :set_filter => 0, :project_id => nil}, :caption => :label_user_allocations, :if => Proc.new {User.current.allowed_to?(:view_easy_user_allocations, nil, :global => true) || User.current.allowed_to?(:view_my_easy_user_allocations, nil, :global => true)}, :before => :administration
  end

  Redmine::MenuManager.map :project_menu do |menu|
    menu.push :user_allocations, {:controller => 'user_allocation_gantt', :action => 'index'}, :param => :project_id, :caption => :label_user_allocations, :if => Proc.new {|p| User.current.allowed_to?(:view_easy_user_allocations, p) || User.current.admin?}
  end

  require 'easy_user_allocations/hooks'

end

require 'easy_user_allocations/easy_user_allocations_orphans'
EasyExtensions::Orphans.map do |orphans_mapper|
  orphans_mapper.register_plugin EasyExtensions::EasyUserAllocationsOrphans.new
end

EasyQuery.map do |query|
  query.register EasyUserAllocationQuery, {:easy_query_settings_partial => 'easy_user_allocation_queries/easy_query_settings'}
end
