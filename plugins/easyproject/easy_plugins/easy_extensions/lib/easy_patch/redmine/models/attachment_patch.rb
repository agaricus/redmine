module EasyPatch
  module AttachmentPatch

    def self.included(base)
      base.extend(ClassMethods)
      base.send(:include, InstanceMethods)

      base.class_eval do

        remove_validation :description
        validates :description, :presence => true, :length => {:maximum => 255}, :if => :description_required?

        acts_as_versioned :association_options => {:dependent => :destroy }, :if => Proc.new{|p| !p.container_id.nil?}

        acts_as_restricted :restricted_object => :container, :easy_permission_name => [:read, :manage],
          :if => Proc.new{|att| att.container_type == 'Document'}

        acts_as_user_readable

        self.non_versioned_columns << 'downloads'
        self.non_versioned_columns << 'category'

        alias_method_chain :delete_from_disk, :easy_extensions
        alias_method_chain :sanitize_filename, :easy_extensions
        alias_method_chain :validate_max_file_size, :easy_extensions

        class << self

          def sanitize_filename(value)
            # get only the filename, not the whole path
            just_filename = value.gsub(/\A.*(\\|\/)/m, '')

            # Finally, replace invalid characters with underscore
            @filename = just_filename.gsub(/[\/\?\%\*\:\|\"\'<>\n\r]+/, '_')
          end

          def attachment_reminder_words
            '(^|\\W)(' + EasySetting.value('attachment_reminder_words').gsub(/[\n,;]/,'|').tr(" \t\r",'').gsub(/\?/,'.?').gsub(/\*/,'.*').tr_s('|', '|').chomp('|') + ')($|\\W)'
          end

        end

        def current_version
          return @current_version if @current_version
          @current_version ||= self.versions.detect {|v| v.version == self.version}
          @current_version ||= self.versions.last
          @current_version ||= Attachment::Version.new
          return @current_version
        end

        def description_required?
          !!EasySetting.value('attachment_description_required') && !self.new_record?
        end

      end
    end

    module InstanceMethods

      def validate_max_file_size_with_easy_extensions
        if self.filesize > Setting.attachment_max_size.to_i.kilobytes
          errors.add(:base, :too_long, :count => Setting.attachment_max_size.to_i.kilobytes, :message => self.filename + ' - ' + l(:error_validates_max_size) + " (#{(self.filesize.kilobytes / 1000).round} kB)" )
        end
      end

      # Deletes file on the disk (only whether file is used once)
      def delete_from_disk_with_easy_extensions
        delete_from_disk! if !filename.blank? && (Attachment.where(:disk_filename => self.disk_filename).count == 0)
      end

      private

      def sanitize_filename_with_easy_extensions(value)
        @filename = self.class.sanitize_filename(value)
      end


    end

    module ClassMethods

    end

  end

  module AttachmentVersionPatch

    def self.included(base)

      base.class_eval do

        belongs_to :container, :polymorphic => true
        #belongs_to :attachment, :polymorphic => true
        belongs_to :author, :class_name => "User", :foreign_key => "author_id"

        after_destroy :delete_files

        acts_as_user_readable

        def project
          self.attachment.project
        end

        def visible?(user=User.current)
          self.attachment.visible?(user=User.current)
        end

        def deletable?(user=User.current)
          self.attachment.deletable?(user=User.current)
        end

        def image?
          self.attachment.image?
        end

        def is_text?
          self.attachment.is_text?
        end

        def is_diff?
          self.attachment.is_diff?
        end

        def readable?
          self.attachment.readable?
        end

        def diskfile
          File.join(Attachment.storage_path, self.disk_directory.to_s, self.disk_filename.to_s)
        end

        def delete_files
          File.delete(self.diskfile) if !self.filename.blank? && File.exist?(self.diskfile) && (Attachment.count(:conditions => {:disk_filename => self.disk_filename}) == 0)
          if self.attachment.versions.blank?
            self.attachment.destroy
          end
          if self.attachment.version == self.version
            self.attachment.revert_to!(self.previous)
          end
        end

      end

    end

  end
end
EasyExtensions::PatchManager.register_model_patch 'Attachment', 'EasyPatch::AttachmentPatch'
EasyExtensions::PatchManager.register_model_patch 'Attachment::Version', 'EasyPatch::AttachmentVersionPatch'
