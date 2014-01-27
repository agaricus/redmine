module EasyPatch
  module LabelledFromBuilderPatch

    def self.included(base)
      base.extend(ClassMethods)
      base.send(:include, InstanceMethods)

      base.class_eval do
        
        alias_method_chain :label_for_field, :easy_extensions

        def check_box(field, options = {}, checked_value = '1', unchecked_value = '0')
          label_for_field(field, options).html_safe + super(field, options.except(:label),  checked_value, unchecked_value).html_safe
        end

        class << self

        end

      end

    end

    module InstanceMethods
            
      def label_for_field_with_easy_extensions(field, options = {})
        return ''.html_safe if options.delete(:no_label)
        text = options[:label].is_a?(Symbol) ? l(options[:label]) : options[:label]
        text ||= l(("field_" + field.to_s.gsub(/\_id$/, '')).to_sym)
        
        additional_classes = []
        additional_classes << 'error' if @object && @object.errors[field].present?

        if options.delete(:required)
          text += @template.content_tag(:span, ' *', :class => 'required')
          additional_classes << 'required'
        end

        additional_for = '_'
        if options.key?(:additional_for)
          additional_for << options.delete(:additional_for).to_s + '_'
        end
        
        @template.content_tag(:label, text.html_safe,
          :class => additional_classes.join(' '),
          :for => (@object_name.to_s + additional_for + field.to_s))
      end
    end

    module ClassMethods

    end

  end

end
EasyExtensions::PatchManager.register_other_patch 'Redmine::Views::LabelledFormBuilder', 'EasyPatch::LabelledFromBuilderPatch'
