Redmine::Plugin.register :easy_budgetsheet do
  name :budgetsheet_name
  author :budgetsheet_author
  author_url :budgetsheet_author_url
  description :budgetsheet_description
  version '2013'
  migration_order 300
  requires_redmine_plugin :easy_extensions, :version => '2013.08.04'
  plugin_in_relative_subdirectory File.join('easyproject', 'easy_plugins')
end
