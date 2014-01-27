Redmine::Plugin.register :easy_redmine do
  visible false
  migration_order 300

  plugin_in_relative_subdirectory File.join('easyproject', 'easy_plugins')
end
