Redmine::Plugin.register :easy_agile_board do
  name :easy_agile_board_plugin_name
  author :easy_agile_board_plugin_author
  author_url :easy_agile_board_plugin_author_url
  description :easy_agile_board_plugin_description
  version '2013'
  migration_order 300
  requires_redmine_plugin :easy_extensions, :version => '2013.8.4'
  plugin_in_relative_subdirectory File.join('easyproject', 'easy_plugins')
  settings :partial => 'extensions/settings/easy_agile_board', :default => {}
end

# No more lines here!
