Redmine::AccessControl.update_permission :add_project, {}, :global => true
Redmine::AccessControl.update_permission :move_issues, {:issue_moves => [:available_issues]}
Redmine::AccessControl.update_permission :add_issues, {:my => [:new_my_page_create_issue], :issues => [:new_for_dialog]}
Redmine::AccessControl.update_permission :add_documents, {:documents => [:select_project]}
Redmine::AccessControl.update_permission :edit_documents, {:documents => [:select_project]}
Redmine::AccessControl.update_permission :view_gantt, {:gantts => [:render_to_fullscreen, :projects]}, :read => true
Redmine::AccessControl.update_permission :edit_issues, {:issues => [:update_form], :gantts => [:update_issues, :validate_issue], :easy_issues => [:description_edit, :description_update, :edit_toggle_description], :easy_issue_timers => [:play, :stop, :pause]}
Redmine::AccessControl.update_permission :view_time_entries, {:bulk_time_entries => [:index, :load_users, :load_assigned_projects, :load_assigned_issues, :load_fixed_activities, :select_issue]}, :global => true
Redmine::AccessControl.update_permission :view_news, {}, {:public => false}
Redmine::AccessControl.update_permission :log_time, {:bulk_time_entries => [:index, :load_users, :load_assigned_projects, :load_assigned_issues, :load_fixed_activities, :save]}
Redmine::AccessControl.update_permission :manage_issue_relations, {:issue_relations => [:put_between]}
Redmine::AccessControl.update_permission :view_project, {:projects => [:load_allowed_parents]}
Redmine::AccessControl.update_permission :manage_categories, {:issue_categories => [:move_category]}

Redmine::AccessControl.map do |map|

  map.permission :manage_page_project_overview, {:projects => :personalize_show}

  map.permission :archive_project, {:projects => [:archive, :unarchive]}
  map.permission :delete_project, {:projects => [:destroy]}
  map.permission :edit_own_projects, {:projects => [:settings, :edit, :update]}, :require => :loggedin, :global => true
  map.permission :edit_project_custom_fields, {:projects => [:edit_custom_fields_form, :update_custom_fields_form]}, :require => :member
  map.permission :create_project_from_template, {:templates => :index}, :read => true, :global => true
  map.permission :create_project_template, {:templates => [:new, :create]}
  map.permission :edit_project_template, {}, :global => true
  map.permission :delete_project_template, {:templates => [:destroy, :bulk_destroy]}, :global => true
  map.permission :view_project_activity, { :activities => :index }, :public => true, :read => true
  map.permission :view_project_report, { :reports => :issue_report }, :read => true
  map.permission :edit_issue_fixed_activity, {}
  map.permission :copy_project, {:projects => [:copy]}, :read => true
  map.permission :manage_easy_project_relations, {:easy_project_relations => [:destroy]}, :global => true
  map.permission :manage_easy_version_relations, {:easy_version_relations => [:destroy]}
  map.permission :view_project_overview_users_query, {}, :read => true
  map.permission :manage_bulk_version, {:versions => [:bulk_edit, :bulk_update, :bulk_destroy]}

  map.permission :manage_global_versions, {:easy_versions => [:index, :new, :create]}

  map.permission :manage_easy_issue_timers, {:easy_issue_timers => [:settings, :update_settings]}

  map.project_module :issue_tracking do |pmap|
    pmap.permission :view_restrictions_users, {}, :read => true
    pmap.permission :edit_own_issue, {:issues => [:edit, :reply, :bulk_edit, :update_form], :easy_issues => [:description_edit, :description_update]}
    pmap.permission :action_duplicate_issue, { :issues => [:new, :update_form] }
  end

  map.project_module :time_tracking do |pmap|
    pmap.permission :view_personal_statement, {:timelog => :index}, :read => true, :global => true
    pmap.permission :view_all_statements, {:timelog => :index}, :read => true, :global => true
    pmap.permission :view_estimated_hours, {}, :read => true
    pmap.permission :add_timeentries_for_other_users, {}, :global => true
  end

  map.project_module :easy_attendances do |pmap|
    pmap.permission :view_easy_attendances, {:easy_attendances => [:index, :list, :new, :create, :show, :update, :quick_save, :report, :departure, :arrival]}, :read => true, :require => :loggedin, :global => true
    pmap.permission :edit_easy_attendances, {:easy_attendances => [:edit, :destroy, :bulk_destroy, :bulk_update]}, :require => :loggedin, :global => true
    pmap.permission :edit_own_easy_attendances, {:easy_attendances => [:edit, :destroy, :bulk_destroy, :bulk_update]}, :require => :loggedin, :global => true
    pmap.permission :view_easy_attendances_extra_info, {}, :read => true, :global => true
    pmap.permission :view_easy_attendance_other_users, {}, :read => true, :global => true
  end

  map.project_module :easy_other_permissions do |pmap|
    pmap.permission :manage_easy_resource_booking_module, {:easy_resource_availabilities => [:edit_page_layout]}, :global => true
    pmap.permission :manage_my_page, {:my => [:page_layout]}, :global => true
  end

end
