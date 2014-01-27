module EasyPatch
	module RedmineCustomFieldsPatch
    def self.included(base)
      base.send(:include, InstanceMethods)
      base.class_eval do

        alias_method_chain :settings, :easy_extensions if instance_methods.detect{|m| m.to_s == 'settings'}

      end
    end

    module InstanceMethods
      
      def settings_with_easy_extensions
        possibly_serialized = settings_without_easy_extensions
        if possibly_serialized.is_a?(ActiveRecord::AttributeMethods::Serialization::Attribute)
          return possibly_serialized.unserialize
        else
          return possibly_serialized
        end
      end

    end

  end
end
EasyExtensions::PatchManager.register_model_patch ['DocumentCategoryCustomField', 'GroupCustomField', 'IssueCustomField', 'IssuePriorityCustomField',
  'ProjectCustomField', 'TimeEntryActivityCustomField', 'TimeEntryCustomField', 'UserCustomField', 
  'VersionCustomField'], 'EasyPatch::RedmineCustomFieldsPatch', :after => 'CustomField'
