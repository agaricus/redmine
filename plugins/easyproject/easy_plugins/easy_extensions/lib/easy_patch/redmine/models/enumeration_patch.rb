module EasyPatch
  module EnumerationPatch

    def self.included(base)
      base.extend ClassMethods
      base.send(:include, InstanceMethods)
      base.class_eval do

        after_save :invalidate_cache

        class << self

          alias_method_chain :default, :easy_extensions

          def invalidate_cache
            @default_enum = nil
          end
        end

        def invalidate_cache
          self.class.invalidate_cache
        end

      end
    end

    module InstanceMethods

    end

    module ClassMethods

      # adds a cache on this method.
      def default_with_easy_extensions
        @default_enum ||= default_without_easy_extensions
      end

    end

  end
end
EasyExtensions::PatchManager.register_model_patch 'Enumeration', 'EasyPatch::EnumerationPatch'
