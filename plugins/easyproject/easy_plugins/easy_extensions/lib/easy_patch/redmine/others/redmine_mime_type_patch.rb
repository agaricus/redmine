module EasyPatch
  module RedmineMimeTypePatch

    def self.included(base)
      base.extend(ClassMethods)
      base.send(:include, InstanceMethods)

      base.class_eval do

        mattr_reader :registered_additional_extensions
        @@registered_additional_extensions = {}

        class << self

          alias_method_chain :of, :easy_extensions

          def register_mime_type(mime_type, file_extension)
            @@registered_additional_extensions ||= {}
            @@registered_additional_extensions[file_extension.strip.downcase] = mime_type.strip.downcase unless @@registered_additional_extensions.key?(file_extension.strip.downcase)
          end

        end

      end
    end

    module InstanceMethods

    end

    module ClassMethods

      def of_with_easy_extensions(name)
        return nil unless name
        original = of_without_easy_extensions(name)
        return original unless original.blank?
        return nil if registered_additional_extensions.blank?
        m = name.to_s.match(/(^|\.)([^\.]+)$/)
        registered_additional_extensions[m[2]] if m
      end

    end

  end

end
EasyExtensions::PatchManager.register_other_patch 'Redmine::MimeType', 'EasyPatch::RedmineMimeTypePatch'
