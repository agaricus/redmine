module EasyPatch
  module SettingsHelperPatch

    def self.included(base)
      base.send(:include, InstanceMethods)
      base.class_eval do

        alias_method_chain :administration_settings_tabs, :easy_extensions

      end
    end

    module InstanceMethods

      def administration_settings_tabs_with_easy_extensions
        tabs = [{:name => 'general', :partial => 'settings/general', :label => :label_general},
          {:name => 'display', :partial => 'settings/display', :label => :label_display},
          {:name => 'authentication', :partial => 'settings/authentication', :label => :label_authentication},
          {:name => 'projects', :partial => 'settings/projects', :label => :label_project_plural},
          {:name => 'issues', :partial => 'settings/issues', :label => :label_issue_tracking},
          {:name => 'timeentries', :partial => 'settings/timeentries', :label => :label_time_tracking},
          {:name => 'notifications', :partial => 'settings/notifications', :label => :field_mail_notification},
          {:name => 'mail_handler', :partial => 'settings/mail_handler', :label => :label_incoming_emails},
          {:name => 'repositories', :partial => 'settings/repositories', :label => :label_repository_plural}
        ]

        tabs.delete_if{|tab| EasyExtensions::EasyProjectSettings.disabled_features[:administration_setings_tabs].include?(tab[:name])}
        tabs
      end

    end
  end
end
EasyExtensions::PatchManager.register_helper_patch 'SettingsHelper', 'EasyPatch::SettingsHelperPatch'
