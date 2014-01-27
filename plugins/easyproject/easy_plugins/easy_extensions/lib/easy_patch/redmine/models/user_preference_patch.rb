module EasyPatch
  module UserPreferencePatch

    def self.included(base)
      base.extend(ClassMethods)
      base.send(:include, InstanceMethods)

      base.class_eval do

        def no_notified_if_issue_closing; self[:no_notified_if_issue_closing] end
        def no_notified_if_issue_closing=(value); self[:no_notified_if_issue_closing]=value end

        def no_notification_ever; self[:no_notification_ever] end
        def no_notification_ever=(value); self[:no_notification_ever]=value end

      end
    end

    module InstanceMethods
    end

    module ClassMethods
    end

  end

end
EasyExtensions::PatchManager.register_model_patch 'UserPreference', 'EasyPatch::UserPreferencePatch'
