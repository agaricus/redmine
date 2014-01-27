Redmine::Plugin.register :easy_cocoon do
  visible false
  migration_order 100

  plugin_in_relative_subdirectory File.join('easyproject', 'easy_helpers')
end

# Cannot be in Rails.configuration.to_prepare due to some weird 3th party plugins
ActionDispatch::Reloader.to_prepare do
  require 'cocoon/view_helpers'
  ApplicationHelper.send :include, Cocoon::ViewHelpers
end
