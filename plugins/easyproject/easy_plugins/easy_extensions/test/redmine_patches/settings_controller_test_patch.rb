require File.expand_path('../redmine_test_patch', __FILE__)

module EasyExtensions
  module SettingsControllerTestPatch
    extend RedmineTestPatch

    disable_test :test_get_edit_should_preselect_default_issue_list_columns
    disable_test :test_post_plugin_settings

  end
end
