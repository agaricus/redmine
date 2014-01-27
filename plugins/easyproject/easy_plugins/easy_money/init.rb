Redmine::Plugin.register :easy_money do
  name :easy_money_plugin_name
  author :easy_money_plugin_author
  author_url :easy_money_plugin_author_url
  description :easy_money_plugin_description
  version '2013'
  migration_order 300
  requires_redmine_plugin :easy_extensions, :version => '2013.08.04'
  plugin_in_relative_subdirectory File.join('easyproject', 'easy_plugins')
end
