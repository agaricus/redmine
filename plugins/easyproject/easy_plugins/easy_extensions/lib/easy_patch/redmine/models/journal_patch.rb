module EasyPatch
  module JournalPatch

    def self.included(base)
      base.extend(ClassMethods)
      base.send(:include, InstanceMethods)

      base.class_eval do

        has_many :easy_permissions, :as => :entity, :class_name => 'EasyPermission'

        html_fragment :notes, :scrub => :strip

        before_save :cancel_save
        after_initialize :default_values
        after_initialize :gsub_note_from_textile

        alias_method_chain :cache_key, :easy_extensions
        alias_method_chain :send_notification, :easy_extensions

        def default_values
          begin; self.created_on ||= DateTime.now; rescue; end
        end

        def gsub_note_from_textile
          unless new_record?
            self.notes = self.notes && self.notes.gsub(/^[\ ]*(&gt;[\ ]*)*/){|match| "> " * match.scan(/&gt;/).size}
          end
        end

        def cancel_save
          false if self.project && self.project.easy_is_easy_template?
        end

      end
    end

    module InstanceMethods

      def cache_key_with_easy_extensions
        if new_record?
          'journals/new'
        else
          "journals/#{id}-#{created_on.strftime('%Y%m%d%H%M%S')}"
        end
      end

      def send_notification_with_easy_extensions
        return unless self.journalized.is_a?(Issue)
        return if (self.user && self.user.pref[:no_notification_ever] == true)

        if self.notify? &&
            (Setting.notified_events.include?('issue_updated') ||
              (Setting.notified_events.include?('issue_note_added') && self.notes.present?) ||
              (Setting.notified_events.include?('issue_status_updated') && self.new_status.present?) ||
              (Setting.notified_events.include?('issue_priority_updated') && self.new_value_for('priority_id').present?)
          )
          Mailer.send_mail_issue_edit(self)
        end
      end

    end

    module ClassMethods

    end

  end

end
EasyExtensions::PatchManager.register_model_patch 'Journal', 'EasyPatch::JournalPatch'
