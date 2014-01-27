module EasyPatch
  module GroupPatch

    def self.included(base)
      base.send(:include, InstanceMethods)

      base.class_eval do

        safe_attributes 'easy_system_flag'

        alias_method_chain :user_added, :easy_extensions
        alias_method_chain :user_removed, :easy_extensions

      end
    end

    module InstanceMethods

      def user_added_with_easy_extensions(user)
        user_added_without_easy_extensions(user)
        Redmine::Hook.call_hook(:model_group_user_added_after_save, { :user => user})
      end

      def user_removed_with_easy_extensions(user)
        user_removed_without_easy_extensions(user)
        Redmine::Hook.call_hook(:model_group_user_removed_after_destroy, { :user => user})
      end
      
    end

  end
end
EasyExtensions::PatchManager.register_model_patch 'Group', 'EasyPatch::GroupPatch'
