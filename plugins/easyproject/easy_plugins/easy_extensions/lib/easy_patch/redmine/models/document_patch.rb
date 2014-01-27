module EasyPatch
  module DocumentPatch

    def self.included(base)
      base.send(:include, InstanceMethods)

      base.class_eval do
        remove_validation :title, 'validates_length_of'
        validates_length_of :title, :maximum => 255

        html_fragment :description, :scrub => :strip

        acts_as_restricted :restricted_object => :category, :easy_permission_name => :read
        acts_as_customizable

        searchable_options[:columns] << "#{Attachment.table_name}.filename"
        searchable_options[:columns] << "#{Attachment.table_name}.description"
        searchable_options[:include] = [searchable_options[:include], :attachments].flatten
        searchable_options[:additional_conditions] = "#{Project.table_name}.easy_is_easy_template = #{connection.quoted_false}"

        event_options[:description] = Proc.new{|o| o.description.to_s}

        safe_attributes 'custom_field_values'

        alias_method_chain :recipients, :easy_extensions
        alias_method_chain :attachments_visible?, :easy_extensions
        alias_method_chain :attachments_deletable?, :easy_extensions
        alias_method_chain :visible?, :easy_extensions

      end
    end

    module InstanceMethods

      def attachments_visible_with_easy_extensions?(user=User.current)
        attachments_visible_without_easy_extensions?(user) && !self.active_record_restricted?(user, :read)
      end

      def attachments_deletable_with_easy_extensions?(user=User.current)
        attachments_deletable_without_easy_extensions?(user) && !self.active_record_restricted?(user, :manage)
      end

      def visible_with_easy_extensions?(user=User.current)
        visible_without_easy_extensions?(user) && !self.active_record_restricted?(user, [:read, :manage])
      end

      def recipients_with_easy_extensions
        #notified = project.notified_users
        notified = project.members.collect {|m| m.user}
        notified.reject!{|user| user.mail_notification == 'none'}
        notified.reject!{|user| !visible?(user)}
        notified.collect(&:mail)
      end

    end

  end
end
EasyExtensions::PatchManager.register_model_patch 'Document', 'EasyPatch::DocumentPatch'
