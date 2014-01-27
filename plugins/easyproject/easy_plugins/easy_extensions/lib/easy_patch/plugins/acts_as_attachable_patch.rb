module EasyPatch
  module ActsAsAttachableInstancePatch

    def self.included(base)
      base.send(:include, InstanceMethods)

      base.class_eval do

        alias_method_chain :save_attachments , :easy_extensions

        # Find an attachment that could be versioned
        def get_existing_version(file_filename, attachment)
          (self.attachments + saved_attachments).detect{|i| i.filename == Attachment.sanitize_filename(file_filename) && (attachment['category'] ? attachment['category'] == i.category : true)}
        end

        def after_new_version_create_journal(attachment)
          if self.respond_to?(:current_journal) && !self.current_journal.nil?
            reloaded_attachement = attachment.reload.versions.latest
            self.current_journal.details << JournalDetail.new(:property => 'attachment', :prop_key => reloaded_attachement.id, :value => reloaded_attachement.filename)
          end
        end

        def validate_attachment
          if unsaved_attachments.any?
            self.errors.add(:base, unsaved_attachments.first.errors.full_messages.join(', '))
          end
        end

      end
    end

    module InstanceMethods

      def save_attachments_with_easy_extensions(attachments, author=User.current)
        new_versions = Array.new
        if attachments.is_a?(Hash)
          attachments = attachments.stringify_keys
          attachments = attachments.to_a.sort {|a, b|
            if a.first.to_i > 0 && b.first.to_i > 0
              a.first.to_i <=> b.first.to_i
            elsif a.first.to_i > 0
              1
            elsif b.first.to_i > 0
              -1
            else
              a.first <=> b.first
            end
          }
          attachments = attachments.map(&:last)
        end
        if attachments.is_a?(Array)
          attachments.each do |attachment|
            next unless attachment.is_a?(Hash)
            a = nil
            if file = attachment['file']
              next unless file.size > 0
              select_attachment = get_existing_version(file.original_filename, attachment)
              if select_attachment
                select_attachment.update_attributes(
                  :file => file,
                  :description => attachment['description'].to_s.strip,
                  :container => self,
                  :author => author)
                after_new_version_create_journal(select_attachment)
                new_versions << select_attachment
              else
                a = Attachment.create(:file => file, :author => author, :description => attachment['description'].to_s.strip)
              end
            elsif token = attachment['token']
              a = Attachment.find_by_token(token)
              next unless a
              a.filename = attachment['filename'] unless attachment['filename'].blank?
              a.content_type = attachment['content_type']
              a.description = attachment['description'].to_s.strip
              # Assign new attachment to self
              a.container = self

              select_attachment = get_existing_version(a.filename, attachment)
              if select_attachment && a.valid?
                # Update existing attachment - create new version
                a_attributes = a.attributes.dup
                a_attributes.delete(:id); a_attributes.delete(:version)
                select_attachment.update_attributes(a_attributes)
                new_versions << select_attachment
                # Create journalDetail if possible
                after_new_version_create_journal(select_attachment)
                # delete unused attachment - this attachment is in new version
                a.delete
                a = nil
              end
            end

            next unless a
            if a.new_record? || !a.valid?
              unsaved_attachments << a
            else
              saved_attachments << a
            end
          end
        end
        {:files => saved_attachments, :unsaved => unsaved_attachments, :new_versions => new_versions}
      end

    end

  end


  module ActsAsAttachableClassPatch

    def self.included(base)
      base.send(:include, ClassMethods)

      base.class_eval do

        alias_method_chain :acts_as_attachable, :easy_extensions

      end
    end

    module ClassMethods

      def acts_as_attachable_with_easy_extensions(options = {})
        cattr_accessor :attachable_options
        self.attachable_options = {}
        attachable_options[:view_permission] = options.delete(:view_permission) || "view_#{self.name.pluralize.underscore}".to_sym
        attachable_options[:delete_permission] = options.delete(:delete_permission) || "edit_#{self.name.pluralize.underscore}".to_sym

        has_many :attachments, options.merge(:as => :container,
          :order => "#{Attachment.table_name}.filename",
          :dependent => :destroy)
        send :include, Redmine::Acts::Attachable::InstanceMethods

        validate :validate_attachment

        before_save :attach_saved_attachments
      end

    end

  end
end
EasyExtensions::PatchManager.register_patch_to_be_first 'Redmine::Acts::Attachable::InstanceMethods', 'EasyPatch::ActsAsAttachableInstancePatch', :first => true
EasyExtensions::PatchManager.register_patch_to_be_first 'Redmine::Acts::Attachable::ClassMethods', 'EasyPatch::ActsAsAttachableClassPatch', :first => true
