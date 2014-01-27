module EasyPatch
  module ActsAsWatchablePatch

    def self.included(base)
      base.send(:include, InstanceMethods)

      base.class_eval do

        alias_method_chain :addable_watcher_users, :easy_extensions
        
      end
    end

    module InstanceMethods

      def addable_watcher_users_with_easy_extensions
        if self.is_a?(Issue)
          users = self.project.users.sort - self.watcher_users
          unless User.current.allowed_to?(:add_issue_watchers, self.project)
            users.reject! {|user| !visible?(user)}
          end
          users
        else
          addable_watcher_users_without_easy_extensions
        end
      end

    end

  end
end
EasyExtensions::PatchManager.register_redmine_plugin_patch 'Redmine::Acts::Watchable::InstanceMethods', 'EasyPatch::ActsAsWatchablePatch'
