module EasyPatch
  module ActsAsVersionedPatch

    def self.included(base)
      base.send(:include, InstanceMethods)

      base.class_eval do

        alias_method_chain :save_version_on_create, :easy_extensions

      end
    end

    module InstanceMethods

      def save_version_on_create_with_easy_extensions
        return unless save_version?
        save_version_on_create_without_easy_extensions
      end

    end

  end
end
EasyExtensions::PatchManager.register_redmine_plugin_patch 'ActiveRecord::Acts::Versioned::ActMethods', 'EasyPatch::ActsAsVersionedPatch'
