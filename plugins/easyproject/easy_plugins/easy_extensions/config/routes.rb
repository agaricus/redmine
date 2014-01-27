root :to => 'my#page', :as => 'home'

# account
get 'account/autologin', :to => 'account#autologin'
get 'autologin', :to => 'account#autologin'

# admin
post 'admin/projects', :to => 'admin#projects'

delete 'admin/bulk_destroy', :to => 'admin#bulk_destroy'
post 'admin/bulk_close', :to => 'admin#bulk_close'
post 'admin/bulk_reopen', :to => 'admin#bulk_reopen'
post 'admin/bulk_archive', :to => 'admin#bulk_archive'
post 'admin/bulk_unarchive', :to => 'admin#bulk_unarchive'

# api_custom_fields
resources :api_custom_fields

# api_enumerations
get 'api_enumerations', :to => 'api_enumerations#index'

# api_members
get 'api_members/projects/:project_id.:format', :to => 'api_members#index'
get 'api_members/projects/:project_id/:id.:format', :to => 'api_members#show'
post 'api_members/projects/:project_id.:format', :to => 'api_members#create'
put 'api_members/projects/:project_id/:id.:format', :to => 'api_members#update'
delete 'api_members/projects/:project_id/:id.:format', :to => 'api_members#destroy'

# api_roles
get 'api_roles.:format', :to => 'api_roles#index'
get 'api_roles/:id.:format', :to => 'api_roles#show'
post 'api_roles.:format', :to => 'api_roles#create'
put 'api_roles/:id.:format', :to => 'api_roles#update'
delete 'api_roles/:id.:format', :to => 'api_roles#destroy'

# attachments
get 'attachments/show', :controller => 'attachments'
resources :attachments do
  member do
    match :destroy_version
    match :revert_to_version
  end
end

# auth_sources
match 'auth_sources/:id/move_users', :to => 'auth_sources#move_users', :via => :get

# bulk_time_entries
get 'bulk_time_entries', :to => 'bulk_time_entries#index'
match 'bulk_time_entries', :to => 'bulk_time_entries#save', :via => [:post, :put]
get 'bulk_time_entries/load_users.:format', :to => 'bulk_time_entries#load_users'
get 'bulk_time_entries/load_assigned_projects.:format', :to => 'bulk_time_entries#load_assigned_projects'
get 'bulk_time_entries/load_assigned_issues.:format', :to => 'bulk_time_entries#load_assigned_issues'
get 'bulk_time_entries/load_fixed_activities.:format', :to => 'bulk_time_entries#load_fixed_activities'

# context_menus
match 'context_menus/versioned_attachments', :to => 'context_menus#versioned_attachments'
get 'context_menus/versions', :to => 'context_menus#versions'
get 'context_menus/easy_attendances', :to => 'context_menus#easy_attendances'
get 'context_menus/admin_projects', :to => 'context_menus#admin_projects', :as => 'admin_projects_context_menu'
get 'context_menus/templates', :to => 'context_menus#templates', :as => 'templates_context_menu'
get 'context_menus/easy_rake_tasks', :to => 'context_menus#easy_rake_tasks'

# custom_fields
match 'custom_fields/reload_lookup_settings(/:id)', :to => 'custom_fields#reload_lookup_settings'
match 'custom_fields/:id/toggle_disable', :to => 'custom_fields#toggle_disable', :as => 'custom_field_toogle_disable'

# documents
post 'documents/create', :to => 'documents#create'

# easy_documents
match 'documents', :to => 'easy_documents#index'
get 'documents/new', :to => 'easy_documents#new'
get 'documents/select_project', :to => 'easy_documents#select_project'
get 'documents/:id/new_attachment', :to => 'easy_documents#new_attchments', :as => 'new_attachment_document'

# easy_application_manager
get 'easy_application_manager/plugins_list', :to => 'easy_application_manager#plugins_list'
post 'easy_application_manager/create_package', :to => 'easy_application_manager#create_package'
get 'easy_application_manager/download_package', :to => 'easy_application_manager#download_package'
get 'ep-update', :to => 'easy_application_manager#update_site'

# easy_attendances
resources :easy_attendances do
  collection do
    post :change_activity
    match :quick_save
    delete :bulk_destroy
    put :bulk_update
    match :report, :via => [:get, :post]
    get :new_notify_after_arrived
    post :new_notify_after_arrived, :to => 'easy_attendances#create_notify_after_arrived'
    get :arrival
  end
  member do
    get :departure
  end
end

# easy_attendance_activities
resources :easy_attendance_activities do
  member do
    match :move_attendances, :via => [:get, :post]
  end
  collection do
    match :reload_time_entry_activities
  end
end

# easy_avatars
resource :easy_avatar, :only => [:show, :create, :destroy] do
  collection do
    get :crop, :action => 'crop_avatar'
    post :crop, :action => 'save_avatar_crop'
  end
end

# easy_auto_completes
get 'easy_auto_completes(/:action)', :controller => 'easy_auto_completes'

# easy_cache
match 'easy_cache(/:action)', :controller => 'easy_cache'

# easy_gantt_themes
resources :easy_gantt_themes

# easy_issues
get 'easy_issues/:id/description_edit.:format', :to => 'easy_issues#description_edit'
post 'easy_issues/:id/description_update', :to => 'easy_issues#description_update'
match 'easy_issues/load_assigned_projects.:format', :to => 'easy_issues#load_assigned_projects'
match 'easy_issues/dependent_fields',  :to => 'easy_issues#dependent_fields', :via => [:get, :post]
delete 'easy_issues/:id/remove_child/:child_id', :to => 'easy_issues#remove_child'
match 'issues/:id/preview_external_email', :to => 'easy_issues#preview_external_email'
get 'easy_issues/:id/toggle_description/:element', :to => 'easy_issues#toggle_description'
get 'easy_issues/:id/load_repeating', :to => 'easy_issues#load_repeating', :as => 'easy_issues_load_repeating'
get 'easy_issues/:id/load_history', :to => 'easy_issues#load_history'

# easy_issue_timers
get 'easy_issue_timers/settings', :to => 'easy_issue_timers#settings'
put 'easy_issue_timers/settings', :to => 'easy_issue_timers#update_settings'
post 'issues/:id/play', :to => 'easy_issue_timers#play', :as => :easy_issue_timer_play
post 'issues/:id/stop/:timer_id', :to => 'easy_issue_timers#stop', :as => :easy_issue_timer_stop
post 'issues/:id/pause/:timer_id', :to => 'easy_issue_timers#pause', :as => :easy_issue_timer_pause

# issue categories
put 'issue_categories/:id/move', :to => 'issue_categories#move_category'

# easy_query_settings
match 'easy_query_settings(/:action)', :controller => 'easy_query_settings'

# easy_pages
match 'easy_pages/templates', :to => 'easy_pages#templates'
resources :easy_pages

# easy_page_layout
match 'easy_page_layout/add_module', :to => 'easy_page_layout#add_module'
match 'easy_page_layout/order_module', :to => 'easy_page_layout#order_module'
match 'easy_page_layout/remove_module', :to => 'easy_page_layout#remove_module'
match 'easy_page_layout/save_module', :to => 'easy_page_layout#save_module'
match 'easy_page_layout/layout_from_template', :to => 'easy_page_layout#layout_from_template'
match 'easy_page_layout/layout_from_template_selecting_projects', :to => 'easy_page_layout#layout_from_template_selecting_projects'
match 'easy_page_layout/layout_from_template_selected_projects', :to => 'easy_page_layout#layout_from_template_selected_projects'
match 'easy_page_layout/layout_from_template_selecting_users', :to => 'easy_page_layout#layout_from_template_selecting_users'
match 'easy_page_layout/layout_from_template_selected_users', :to => 'easy_page_layout#layout_from_template_selected_users'
match 'easy_page_layout/layout_from_template_to_all', :to => 'easy_page_layout#layout_from_template_to_all'
get 'easy_page_layout/get_tab_content', :to => 'easy_page_layout#get_tab_content'
match 'easy_page_layout/show_tab', :to => 'easy_page_layout#show_tab'
match 'easy_page_layout/add_tab', :to => 'easy_page_layout#add_tab'
match 'easy_page_layout/edit_tab', :to => 'easy_page_layout#edit_tab'
match 'easy_page_layout/save_tab', :to => 'easy_page_layout#save_tab'
match 'easy_page_layout/remove_tab', :to => 'easy_page_layout#remove_tab'

# easy_page_template_layout
match 'easy_page_template_layout/add_module', :to => 'easy_page_template_layout#add_module'
match 'easy_page_template_layout/order_module', :to => 'easy_page_template_layout#order_module'
match 'easy_page_template_layout/remove_module', :to => 'easy_page_template_layout#remove_module'
match 'easy_page_template_layout/save_module', :to => 'easy_page_template_layout#save_module'
match 'easy_page_template_layout/show_tab', :to => 'easy_page_template_layout#show_tab'
match 'easy_page_template_layout/add_tab', :to => 'easy_page_template_layout#add_tab'
match 'easy_page_template_layout/edit_tab', :to => 'easy_page_template_layout#edit_tab'
match 'easy_page_template_layout/save_tab', :to => 'easy_page_template_layout#save_tab'
match 'easy_page_template_layout/remove_tab', :to => 'easy_page_template_layout#remove_tab'
get 'easy_page_template_layout/get_tab_content', :to => 'easy_page_template_layout#get_tab_content'

# easy_page_templates
match 'easy_page_templates/move', :to => 'easy_page_templates#move'
match 'easy_page_templates/show_page_template', :to => 'easy_page_templates#show_page_template'
match 'easy_page_templates/edit_page_template', :to => 'easy_page_templates#edit_page_template'
resources :easy_page_templates

# easy_page_zones
match 'easy_page_zones/assign_zone', :to => 'easy_page_zones#assign_zone'
resources :easy_page_zones

# easy_project_relations
delete 'easy_project_relations/:id', :to => 'easy_project_relations#destroy'

# easy_publishing_settings
match 'easy_publishing_settings/help_image', :to => 'easy_publishing_settings#help_image'
get 'easy_publishing_settings/dependent_fields', :to => 'easy_publishing_settings#dependent_fields', :as => 'publishing_dependent_fields'
resources :easy_publishing_settings

# easy_queries
get 'easy_queries/filters', :to => 'easy_queries#filters'
resources :easy_queries do
  collection do
    match :easy_document_preview
    match :preview
  end
end

# easy_rating_info
get 'easy_rating_info/:id', :to => 'easy_rating_info#show'

# easy_rake_tasks
resources :easy_rake_tasks do
  member do
    get 'execute'
    get 'task_infos'
    get 'easy_rake_task_info_detail_receive_mail'
    post 'easy_rake_task_easy_helpdesk_receive_mail_status_detail'
  end
end

# easy_resource_availabilities
post 'easy_resource_availabilities/update', :to => 'easy_resource_availabilities#update'
get 'easy_resource_availabilities', :to => 'easy_resource_availabilities#index'
get 'easy_resource_availabilities/page_layout', :to => 'easy_resource_availabilities#edit_page_layout'
# easy_scheduler_tasks_info
match 'easy_scheduler_tasks_info/task_info', :to => 'easy_scheduler_tasks_info#task_info'

# easy_sliding_panel
post 'easy_sliding_panels/save_location', :to => 'easy_sliding_panels#save_location'

# easy_translations
get 'easy_translations/:entity_type/:entity_id/:entity_column', :to => 'easy_translations#index', :as => 'easy_translations'
put 'easy_translations/:entity_type/:entity_id/:entity_column', :to => 'easy_translations#update', :as => 'update_easy_translations'
post 'easy_translations/:entity_type/:entity_id/:entity_column', :to => 'easy_translations#create', :as => 'create_easy_translations'
delete 'easy_translations/:id', :to => 'easy_translations#destroy', :as => 'destroy_easy_translation'

# easy_user_working_time_calendars
resources :easy_user_working_time_calendars do
  collection do
    match 'assign_to_user', :to => 'easy_user_working_time_calendars#assign_to_user'
    match 'mass_exceptions', :to => 'easy_user_working_time_calendars#mass_exceptions'
  end
  member do
    match 'inline_edit', :to => 'easy_user_working_time_calendars#inline_edit'
    match 'inline_update', :to => 'easy_user_working_time_calendars#inline_update'
    match 'inline_show', :to => 'easy_user_working_time_calendars#inline_show'
    match 'reset', :to => 'easy_user_working_time_calendars#reset'
  end
end

# easy_user_time_calendar_holidays
resources :easy_user_time_calendar_holidays

# easy_versions - global versions
get 'versions/new', :to => 'easy_versions#new'
post 'versions/create', :to => 'versions#create'
resources :easy_versions
match 'versions', :controller => 'easy_versions', :action => 'index'
delete 'versions/:version_id/easy_version_relations/:id', :to => 'easy_version_relations#destroy'

# gantts
match 'issues/gantt', :to => 'gantts#show'
match 'projects/gantt', :to => 'gantts#projects'
match 'issues/gantt(/:action)', :controller => 'gantts'
match 'projects/:project_id/issues/gantt/:action', :controller => 'gantts'

# issues
match 'issues/render_last_journal', :controller => 'easy_issues', :action => 'render_last_journal', :via => [:get, :post]
match 'issues/update_form', :controller => 'issues', :action => 'update_form'
match 'issues/new', :to => 'easy_issues#new'
get 'issues/new_for_dialog', :to => 'easy_issues#new_for_dialog'
get 'projects/:project_id/issues/new_for_dialog', :to => 'easy_issues#new_for_dialog', :as => 'issue_from_gantt'
match 'issues/preview/new', :to => 'previews#issue', :via => [:get, :post, :put]

# journals
post 'journals/:id/public', :to => 'journals#public_journal', :as => 'public_journal'

#issue_relations
post 'issue_relations/put_between', :to => 'issue_relations#put_between'

# my
match 'my/update_my_page_new_issue_dependent_fields', :to => 'my#update_my_page_new_issue_dependent_fields'
match 'my/update_my_page_new_issue_attributes', :to => 'my#update_my_page_new_issue_attributes'
post 'my/new_my_page_create_issue', :to => 'my#new_my_page_create_issue'
get 'my/new_my_page_create_issue', :to => 'my#page'
match 'my/update_my_page_module_view', :to => 'my#update_my_page_module_view'
match 'my/toggle_mobile_view', :to => 'my#toggle_mobile_view'
match 'my/toggle_mobile_view', :to => 'my#toggle_mobile_view'
get 'my/mobile_page_layout', :to => 'my#mobile_page_layout'

# projects
get 'projects/my.:format', :to => 'projects#my'
post 'projects/search', :to => 'projects#search'
match 'projects/load_allowed_parents', :to => 'projects#load_allowed_parents'
match 'projects/:id/favorite', :to => 'projects#favorite', :as => 'favorite_project'
match 'projects/:id/personalize_show', :to => 'projects#personalize_show'
match 'projects/toggle_custom_fields_on_project_form', :to => 'projects#toggle_custom_fields_on_project_form'
match 'projects/:project_id/versions/bulk_edit', :to => 'versions#bulk_edit'
put 'projects/:project_id/versions/bulk_update', :to => 'versions#bulk_update'
delete 'projects/:project_id/versions/bulk_destroy', :to => 'versions#bulk_destroy'
get 'projects/:project_id/easy_queries/new', :controller => 'easy_queries', :action => 'new'
get 'projects/:id/edit_custom_fields_form', :to => 'projects#edit_custom_fields_form'
put 'projects/:id/edit_custom_fields_form', :to => 'projects#update_custom_fields_form'

resources :projects do
  member do
    post 'settings(/:tab)', :action => 'settings'
  end
end

# project_mass_copy
get 'project_mass_copy/select_source_project', :to => 'project_mass_copy#select_source_project'
get 'project_mass_copy/:source_project_id/select_target_projects', :to => 'project_mass_copy#select_target_projects'
post 'project_mass_copy/:source_project_id/select_actions', :to => 'project_mass_copy#select_actions'
post 'project_mass_copy/:source_project_id/copy', :to => 'project_mass_copy#copy'

# RSS
match 'rss(/:action)', :controller => 'rss'

get 'easy_repeating/:entity_type(/:entity_id)', :to => 'easy_repeating#show_repeating_options', :as => 'show_repeating_options'
delete 'easy_repeating/:entity_type/:entity_id', :to => 'easy_repeating#disable_repeating', :as => 'disable_easy_repeating'

# modal_selectors
match 'modal_selectors(/:action)', :controller => 'modal_selectors'

# settings
match 'settings/uninstall', :to => 'settings#uninstall'
match 'settings/release_cache', :to => 'settings#release_cache'

# sys
match 'sys/git_fetcher', :to => 'sys#git_fetcher'

# templates
get 'templates', :to => 'templates#index'
get 'templates/:id/restore', :to => 'templates#restore'
get 'templates/:id/add', :to => 'templates#add'
get 'templates/:id/create', :to => 'templates#show_create_project'
get 'templates/:id/copy', :to => 'templates#show_copy_project'
post 'templates/:id/create', :to => 'templates#make_project_from_template'
post 'templates/:id/copy', :to => 'templates#copy_project_from_template'
match 'templates/:id/destroy', :to => 'templates#destroy'
delete 'templates/bulk_destroy', :to => 'templates#bulk_destroy'

# timelog
get 'time_entries', :controller => 'timelog', :action => 'index'
match 'time_entries/user_spent_time', :to => 'timelog#user_spent_time'
match 'time_entries/change_role_activities', :to => 'timelog#change_role_activities'
match 'time_entries/change_projects_for_bulk_edit', :to => 'timelog#change_projects_for_bulk_edit'
match 'time_entries/change_issues_for_bulk_edit', :to => 'timelog#change_issues_for_bulk_edit'
match 'time_entries/change_issues_for_timelog', :to => 'timelog#change_issues_for_timelog'

# timelog_calendar
get 'timelog_calendar/calendar', :controller => 'timelog_calendar', :action => 'calendar'

# trackers
match 'trackers/:id/move_issues', :to => 'trackers#move_issues', :via => [:get, :post], :as => 'tracker_move_issues'
match 'trackers/:id/custom_field_mapping', :to => 'trackers#custom_field_mapping', :via => :get, :as => 'tracker_cf_mapping'

# users
match 'users/generate_rss_key', :controller => 'users', :action => 'generate_rss_key'
match 'users/generate_api_key', :controller => 'users', :action => 'generate_api_key'
post 'users/save_button_settings', :controller => 'users', :action => 'save_button_settings'
match 'users/save_publishing_state', :controller => 'users', :action => 'save_publishing_state'

# versions
match 'versions/toggle_roadmap_trackers', :to => 'versions#toggle_roadmap_trackers'
post 'versions/bulk_edit', :to => 'versions#bulk_edit'
put 'versions/bulk_update', :to => 'versions#bulk_update'
delete 'versions/bulk_destroy', :to => 'versions#bulk_destroy'

# watchers
post 'watchers/new', :to => 'watchers#new'
get 'watchers/toggle_members', :to => 'watchers#toggle_members'

# easy_xml_data
get 'easy_xml_data/import_settings', :to => 'easy_xml_data#import_settings'
match 'easy_xml_data/import', :to => 'easy_xml_data#import'
post 'easy_xml_data/map', :to => 'easy_xml_data#map'

# easy_oauth
get '/easy_external_authentications/:provider/:type/new' => 'easy_external_authentications#new', :type => /(application|user)/, :as => 'easy_external_authentication'
match '/oauth/:provider/callback' => 'easy_external_authentications#create', :via => [:get, :post], :as => 'easy_external_authentication_callback'
delete '/easy_external_authentications/:id/' => 'easy_external_authentications#destroy', :as => 'easy_external_authentication_destroy'
