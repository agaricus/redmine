module EasyPatch
  module MemberPatch

    def self.included(base)
      base.send(:include, InstanceMethods)
      base.class_eval do

        after_create :copy_mail_notification_from_parent

      end
    end

    module InstanceMethods

      def copy_mail_notification_from_parent(parent_id=nil)
        parent_id ||= project.parent.id if project && project.parent
        if parent_id && user
          membership = Member.find(:first, :conditions => {:user_id => user.id, :project_id => parent_id})
          if membership and membership.mail_notification
            update_attributes(:mail_notification => true)
          end
        end
      end

    end

  end
end
EasyExtensions::PatchManager.register_model_patch 'Member', 'EasyPatch::MemberPatch'
