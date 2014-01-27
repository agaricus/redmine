Redmine::Plugin.register :easy_user_allocations do
  name :easy_user_allocations_name
  author :easyproject_author
  author_url :easyproject_author_url
  description :easy_user_allocations_description
  version '2013'
  migration_order 300
  requires_redmine_plugin :easy_extensions, :version => '2013.08.04'
  plugin_in_relative_subdirectory File.join('easyproject', 'easy_plugins')
  settings :partial => 'extensions/settings/easy_user_allocations', :default => {}
end
