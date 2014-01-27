module EasyPatch
  module GroupsHelperPatch

    def self.included(base)
      base.send(:include, InstanceMethods)

      base.class_eval do

        alias_method_chain :group_settings_tabs, :easy_extensions

      end
    end

    module InstanceMethods

      def group_settings_tabs_with_easy_extensions
        tabs = [{:name => 'general', :partial => 'groups/general', :label => :label_general, :no_js_link => true},
          {:name => 'users', :partial => 'groups/users', :label => :label_user_plural, :no_js_link => true},
          {:name => 'memberships', :partial => 'groups/memberships', :label => :label_project_plural, :no_js_link => true}
        ]
      end

    end
  end
end
EasyExtensions::PatchManager.register_helper_patch 'GroupsHelper', 'EasyPatch::GroupsHelperPatch'
