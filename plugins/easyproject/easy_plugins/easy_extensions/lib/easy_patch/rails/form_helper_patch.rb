module EasyPatch
  module FormHelperPatch
    
    module InstanceTag
      def self.included(base)
        base.send(:include, InstanceMethods)

        base.class_eval do

          alias_method_chain :to_input_field_tag, :easy_extensions

        end
      end

      module InstanceMethods

        def to_input_field_tag_with_easy_extensions(field_type, options = {})
          options.delete(:label)
          to_input_field_tag_without_easy_extensions(field_type, options)
        end

      end
    end
    
  end
end
EasyExtensions::PatchManager.register_rails_patch 'ActionView::Helpers::InstanceTag', 'EasyPatch::FormHelperPatch::InstanceTag'
