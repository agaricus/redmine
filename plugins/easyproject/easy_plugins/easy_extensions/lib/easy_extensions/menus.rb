Redmine::MenuManager.map :admin_menu do |menu|
  menu.delete :projects
  menu.delete :users
  menu.delete :groups
  menu.delete :roles
  menu.delete :trackers
  menu.delete :issue_statuses
  menu.delete :workflows
  menu.delete :custom_fields
  menu.delete :enumerations
  menu.delete :settings
  menu.delete :ldap_authentication
  menu.delete :plugins
  menu.delete :info

  menu.push :projects, {:controller => 'admin', :action => 'projects'}, :caption => :label_project_plural, :if => Proc.new { User.current.easy_lesser_admin_for?(:projects) }, :html => {:class => 'icon icon-project'}
  menu.push :templates, {:controller => 'templates', :action => 'index'}, :caption => :label_templates_plural, :if => Proc.new { User.current.easy_lesser_admin_for?(:templates) || User.current.allowed_to?(:create_project_from_template, nil, :global => true) }, :after => :projects, :html => {:class => 'icon icon-templates'}
  menu.push :users, {:controller => 'users'}, :caption => :label_user_plural, :if => Proc.new { User.current.easy_lesser_admin_for?(:users) }, :html => {:class => 'icon icon-user'}
  menu.push :groups, {:controller => 'groups'}, :caption => :label_group_plural, :if => Proc.new { User.current.easy_lesser_admin_for?(:groups) }, :html => {:class => 'icon icon-group'}
  menu.push :working_time, {:controller => 'easy_user_working_time_calendars', :action => 'index'}, :caption => :label_admin_easy_user_working_time_calendars, :html => {:class => 'icon icon-calendar'}, :if => Proc.new { User.current.easy_lesser_admin_for?(:working_time) }, :after => :groups
  menu.push :roles, {:controller => 'roles'}, :caption => :label_role_and_permissions, :if => Proc.new { User.current.easy_lesser_admin_for?(:roles) }, :html => {:class => 'icon icon-roles'}
  menu.push :trackers, {:controller => 'trackers'}, :caption => :label_tracker_plural, :if => Proc.new { User.current.easy_lesser_admin_for?(:trackers) }, :html => {:class => 'icon icon-tracker'}
  menu.push :issue_statuses, {:controller => 'issue_statuses'}, :caption => :label_issue_status_plural, :html => {:class => 'icon icon-issue-status'}, :if => Proc.new { User.current.easy_lesser_admin_for?(:issue_statuses) }
  menu.push :workflows, {:controller => 'workflows', :action => 'edit'}, :caption => :label_workflow, :if => Proc.new { User.current.easy_lesser_admin_for?(:workflows) }, :html => {:class => 'icon icon-workflow'}
  menu.push :easy_issue_timer_settings, {:controller => 'easy_issue_timers', :action => 'settings'}, :caption => :label_easy_issue_timer_settings, :html => {:class => 'icon icon-timer'}, :if => Proc.new { User.current.easy_lesser_admin_for?(:easy_issue_timer_settings) }
  menu.push :custom_fields, {:controller => 'custom_fields'}, :caption => :label_custom_field_plural, :html => {:class => 'icon icon-cf'}, :if => Proc.new { User.current.easy_lesser_admin_for?(:custom_fields) }
  menu.push :enumerations, {:controller => 'enumerations'}, :if => Proc.new { User.current.easy_lesser_admin_for?(:enumerations) }, :html => {:class => 'icon icon-list'}
  menu.push :easy_query_settings, {:controller => 'easy_query_settings', :action => 'index'}, :caption => :label_easy_query_settings, :html => {:class => 'icon icon-filter'}, :if => Proc.new { User.current.easy_lesser_admin_for?(:easy_query_settings) }, :after => :settings
  menu.push :ldap_authentication, {:controller => 'auth_sources', :action => 'index'}, :if => Proc.new { User.current.easy_lesser_admin_for?(:ldap_authentication) }, :html => {:class => 'icon icon-server'}
  menu.push :easy_pages_administration, { :controller => 'easy_pages', :action => 'index' }, :caption => :label_easy_pages_project_administration, :if => Proc.new { User.current.easy_lesser_admin_for?(:easy_pages_administration) }, :html => {:class => 'icon icon-page'}
  menu.push :easy_rake_tasks, { :controller => 'easy_rake_tasks', :action => 'index' }, :caption => :'easy_rake_tasks.views.button_index', :if => Proc.new { User.current.easy_lesser_admin_for?(:easy_rake_tasks) }, :html => {:class => 'icon icon-stack'}
  menu.push :easy_publishing_modules, { :controller => 'easy_publishing_settings', :action => 'index' }, :if => Proc.new { EasyPublishingSetting.editable? }, :html => {:class => 'icon icon-fav-off'}
  menu.push :easy_xml_data_import, {:controller => 'easy_xml_data', :action => 'import_settings'}, :caption => :label_xml_data_import, :if => Proc.new{|p| User.current.easy_lesser_admin_for?(:easy_xml_data_import)}, :html => {:class => 'icon icon-import'}
  menu.push :settings, {:controller => 'settings'}, :if => Proc.new { User.current.easy_lesser_admin_for?(:settings) }, :html => {:class => 'icon icon-settings'}
  menu.push :easy_gantt_themes, {:controller => 'easy_gantt_themes', :action => 'index'}, :html => {:class => 'icon icon-watcher'}, :caption => :label_easy_gantt_theme_plural, :if => Proc.new { User.current.easy_lesser_admin_for?(:easy_gantt_themes) }
  menu.push :plugins, {:controller => 'admin', :action => 'plugins'}, :if => Proc.new { User.current.easy_lesser_admin_for?(:plugins) }, :html => {:class => 'icon icon-package'}, :last => true
end

Redmine::MenuManager.map :admin_dashboard do |menu|
  menu.push :projects, {:controller => 'admin', :action => 'projects'}, :caption => :label_project_plural, :if => Proc.new { User.current.easy_lesser_admin_for?(:projects) }, :html => {:menu_category => 'projects', :class => 'icon icon-project'}
  menu.push :templates, {:controller => 'templates', :action => 'index'}, :caption => :label_templates_plural, :if => Proc.new { User.current.easy_lesser_admin_for?(:templates) || User.current.allowed_to?(:create_project_from_template, nil, :global => true) }, :after => :projects, :html => {:menu_category => 'projects', :class => 'icon icon-templates'}
  menu.push :trackers, {:controller => 'trackers'}, :caption => :label_tracker_plural, :if => Proc.new { User.current.easy_lesser_admin_for?(:trackers) }, :html => {:menu_category => 'issues', :class => 'icon icon-tracker'}
  menu.push :issue_statuses, {:controller => 'issue_statuses'}, :caption => :label_issue_status_plural, :html => {:menu_category => 'issues', :class => 'icon icon-issue-status'}, :if => Proc.new { User.current.easy_lesser_admin_for?(:issue_statuses) }
  menu.push :workflows, {:controller => 'workflows', :action => 'edit'}, :caption => :label_workflow, :if => Proc.new { User.current.easy_lesser_admin_for?(:workflows) }, :html => {:menu_category => 'issues', :class => 'icon icon-workflow'}
  menu.push :users, {:controller => 'users'}, :caption => :label_user_plural, :if => Proc.new { User.current.easy_lesser_admin_for?(:users) }, :html => {:menu_category => 'users', :class => 'icon icon-user'}
  menu.push :groups, {:controller => 'groups'}, :caption => :label_group_plural, :if => Proc.new { User.current.easy_lesser_admin_for?(:groups) }, :html => {:menu_category => 'users', :class => 'icon icon-group'}
  menu.push :ldap_authentication, {:controller => 'auth_sources', :action => 'index'}, :html => {:menu_category => 'security', :class => 'icon icon-server'}, :if => Proc.new { User.current.easy_lesser_admin_for?(:ldap_authentication) }
  menu.push :roles, {:controller => 'roles'}, :caption => :label_role_and_permissions, :if => Proc.new { User.current.easy_lesser_admin_for?(:roles) }, :html => {:menu_category => 'security', :class => 'icon icon-roles'}
  #  menu.push :easy_xml_data_import, {:controller => 'easy_xml_data', :action => 'import_settings'}, :caption => :label_xml_data_import, :if => Proc.new{|p| User.current.admin?}, :html => { :menu_category => 'xml'}
  menu.push :easy_publishing_modules, { :controller => 'easy_publishing_settings', :action => 'index' }, :if => Proc.new { EasyPublishingSetting.editable? }, :html => {:menu_category => 'extensions', :class => 'icon icon-fav-off'}
  menu.push :plugins, {:controller => 'admin', :action => 'plugins'}, :if => Proc.new { User.current.easy_lesser_admin_for?(:plugins) }, :last => true, :html => {:menu_category => 'extensions', :class => 'icon icon-package'}
  menu.push :working_time, {:controller => 'easy_user_working_time_calendars', :action => 'index'}, :caption => :label_admin_easy_user_working_time_calendars, :html => {:menu_category => 'settings', :class => 'icon icon-calendar'}, :if => Proc.new { User.current.easy_lesser_admin_for?(:working_time) }, :after => :groups
  menu.push :custom_fields, {:controller => 'custom_fields'}, :caption => :label_custom_field_plural, :html => {:menu_category => 'settings', :class => 'icon icon-cf'}, :if => Proc.new { User.current.easy_lesser_admin_for?(:custom_fields) }
  menu.push :enumerations, {:controller => 'enumerations'}, :if => Proc.new { User.current.easy_lesser_admin_for?(:enumerations) }, :html => {:menu_category => 'settings', :class => 'icon icon-list'}
  menu.push :easy_query_settings, {:controller => 'easy_query_settings', :action => 'index'}, :caption => :label_easy_query_settings, :html => { :menu_category => 'settings', :class => 'icon icon-filter'}, :if => Proc.new { User.current.easy_lesser_admin_for?(:easy_query_settings) }, :after => :settings
  menu.push :easy_pages_administration, { :controller => 'easy_pages', :action => 'index' }, :caption => :label_easy_pages_project_administration, :if => Proc.new { User.current.easy_lesser_admin_for?(:easy_pages_administration) }, :html => {:menu_category => 'settings', :class => 'icon icon-page'}
  menu.push :settings, {:controller => 'settings'}, :if => Proc.new { User.current.easy_lesser_admin_for?(:settings) }, :html => {:menu_category => 'settings', :class => 'icon icon-settings'}
end

Redmine::MenuManager.map :top_menu do |menu|
  menu.delete :home
  menu.delete :my_page
  menu.delete :projects
  menu.delete :administration
  menu.delete :help

  #menu.push :home, :home_path, :if => Proc.new { !User.current.current_theme_is_easy? }

  menu.push :personal_statement, { :controller => 'timelog', :action => 'index', :only_me => true, :project_id => nil }, :caption => :label_personal_statement, :if => Proc.new { User.current.allowed_to?(:view_personal_statement, nil, :global => true) && EasySetting.value('show_personal_statement')}
  menu.push(:easy_resource_booking_modul, :easy_resource_availabilities_path,
   :caption => :label_easy_resource_booking_module_top_menu,
   :if => Proc.new{ EasySetting.value(:show_easy_resource_booking) }
   )
  menu.push :bulk_time_entry, {:controller => 'bulk_time_entries', :action => 'index'}, :caption => :bulk_time_entry_title, :if => Proc.new{ User.current.allowed_to?(:log_time, nil, :global => true) && EasySetting.value('show_bulk_time_entry')}
  menu.push :documents, {:controller => 'easy_documents', :action => 'index'}, :caption => :label_document_global, :if => Proc.new{ User.current.allowed_to?(:view_documents, nil, :global => true)}, :before => :administration
  menu.push :easy_versions, {:controller => 'easy_versions', :action => 'index'}, :caption => :label_easy_versions_top_menu, :if => Proc.new{ User.current.allowed_to?(:manage_global_versions, nil, :global => true)}
  menu.push :administration, { :controller => 'admin' }, :if => Proc.new { User.current.admin? || User.current.easy_lesser_admin? }
  menu.push :login, :signin_path, :if => Proc.new { User.current.current_theme_is_easy? && !User.current.logged? }, :after => :administration
  menu.push :register, { :controller => 'account', :action => 'register' }, :if => Proc.new { User.current.current_theme_is_easy? && !User.current.logged? && Setting.self_registration? }, :after => :login
  menu.push :my_account, { :controller => 'users', :action => 'show' }, :param => Proc.new{|p| {:id => User.current}}, :if => Proc.new { User.current.current_theme_is_easy? && User.current.logged? }, :after => :administration
  menu.push :logout, :signout_path, :html => {:method => 'post'}, :if => Proc.new { User.current.current_theme_is_easy? && User.current.logged? }, :after => :my_account
  menu.push :help, Redmine::Info.help_url, :if => Proc.new { !User.current.current_theme_is_easy? }, :last => true
end

Redmine::MenuManager.map :account_menu do |menu|
  menu.delete :login
  menu.delete :register
  menu.delete :my_account
  menu.delete :logout
end

Redmine::MenuManager.map :easy_quick_top_menu do |menu|
  menu.push :my_page, { :controller => 'my', :action => 'page' }, :if => Proc.new { User.current.logged? }
  menu.push :projects, { :controller => 'projects', :action => 'index', :set_filter => 0}, :caption => :label_project_plural
  menu.push :issues, { :controller => 'issues', :action => 'index', :set_filter => 0, :project_id => nil}, :caption => :label_issue_plural
end

Redmine::MenuManager.map :project_menu do |menu|
  menu.delete :overview
  menu.delete :activity
  menu.delete :roadmap
  menu.delete :issues
  menu.delete :new_issue
  menu.delete :gantt
  menu.delete :calendar
  menu.delete :news
  menu.delete :documents
  menu.delete :wiki
  menu.delete :boards
  menu.delete :files
  menu.delete :repository
  menu.delete :settings

  menu.push :overview, { :controller => 'projects', :action => 'show' }, :first => true
  menu.push :issues, { :controller => 'issues', :action => 'index' }, :param => :project_id, :caption => :label_issue_plural, :if => Proc.new { |p| User.current.allowed_to?(:view_issues, p) }
  menu.push :new_issue, { :controller => 'issues', :action => 'new', :copy_from => nil }, :param => :project_id, :caption => :label_issue_new, :if => Proc.new { |p| !User.current.current_theme_is_easy? }
  menu.push :spent_time, { :controller => 'timelog', :action => 'index' }, :param => :project_id, :caption => :label_spent_time, :if => Proc.new { |p| User.current.allowed_to?(:view_time_entries, p) }, :after => :new_issue
  menu.push :news, { :controller => 'news', :action => 'index' }, :param => :project_id, :caption => :label_news_plural, :after => :spent_time
  menu.push :documents, { :controller => 'documents', :action => 'index' }, :param => :project_id, :caption => :label_document_plural, :if => Proc.new { |p| User.current.allowed_to?(:view_documents, p) }, :after => :news
  menu.push :roadmap, { :controller => 'versions', :action => 'index' }, :param => :project_id, :caption => :label_roadmap, :if => Proc.new { |p| p.shared_versions.any? }, :after => :documents
  menu.push :calendar, { :controller => 'calendars', :action => 'show' }, :param => :project_id, :caption => :label_calendar, :if => Proc.new { |p| User.current.allowed_to?(:view_calendar, p) && !User.current.in_mobile_view?}
  menu.push :gantt, { :controller => 'gantts', :action => 'show' }, :param => :project_id, :caption => :label_gantt, :if => Proc.new { |p| User.current.allowed_to?(:view_gantt, p) && !User.current.in_mobile_view? }, :after => :calendar
  menu.push :wiki, { :controller => 'wiki', :action => 'show', :id => nil }, :param => :project_id, :if => Proc.new { |p| p.wiki && !p.wiki.new_record? && !EasyExtensions::EasyProjectSettings.disabled_features[:modules].include?('wiki') }
  menu.push :boards, { :controller => 'boards', :action => 'index', :id => nil }, :param => :project_id, :if => Proc.new { |p| p.boards.any? && !EasyExtensions::EasyProjectSettings.disabled_features[:modules].include?('boards') }, :caption => :label_board_plural
  menu.push :files, { :controller => 'files', :action => 'index' }, :caption => :label_file_plural, :param => :project_id, :if => Proc.new { |p| !EasyExtensions::EasyProjectSettings.disabled_features[:modules].include?('files')}
  menu.push :repository, { :controller => 'repositories', :action => 'show', :repository_id => nil, :path => nil, :rev => nil }, :if => Proc.new { |p| p.repository && !p.repository.new_record? && !EasyExtensions::EasyProjectSettings.disabled_features[:modules].include?('repository')}
  menu.push :settings, { :controller => 'projects', :action => 'settings' }, :caption => :label_settings, :if => Proc.new { |p| p.editable? }, :last => true
end

Redmine::MenuManager.map :projects_easy_page_layout_service_box do |menu|
  menu.push :new_project, { :controller => 'projects', :action => 'new' }, :caption => :label_project_new, :html => { :class => 'button-1 icon icon-add' }, :if => Proc.new { User.current.allowed_to?(:add_project, nil, :global => true) || User.current.allowed_to?(:add_subprojects, nil, :global => true) }, :first => true
  menu.push :new_project_from_template, { :controller => 'templates', :action => 'index' }, :html => { :class => 'button-1 icon icon-add' }, :if => Proc.new { User.current.allowed_to?(:create_project_from_template, nil, :global => true) }
  menu.push :spent_time, {:controller => 'timelog', :action => 'index', :set_filter => '0'}, :caption => :label_spent_time, :html => {:class => 'button-2 icon icon-time'}, :if => Proc.new { User.current.allowed_to?(:view_all_statements, nil, :global => true) }
  menu.push :project_gantt, {:controller => 'gantts', :action => 'projects'}, :caption => :label_gantt, :html => {:class => 'button-2 icon icon-report'}, :last => true
end

Redmine::MenuManager.map :admin_projects_easy_page_layout_service_box do |menu|
  menu.push :new_project, { :controller => 'projects', :action => 'new' }, :caption => :label_project_new, :html => { :class => 'button-1 icon icon-add' }, :if => Proc.new { User.current.allowed_to?(:add_project, nil, :global => true) || User.current.allowed_to?(:add_subprojects, nil, :global => true) }, :first => true
  menu.push :new_project_from_template, { :controller => 'templates', :action => 'index' }, :html => { :class => 'button-1 icon icon-add' }, :if => Proc.new { User.current.allowed_to?(:create_project_from_template, nil, :global => true) }
  menu.push :project_mass_copy, { :controller => 'project_mass_copy', :action => 'select_source_project' }, :caption => :button_project_mass_copy, :html => { :class => 'button-2 icon icon-copy' }, :if => Proc.new { User.current.admin? }
end
