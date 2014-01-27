module EasyPatch
  module FormHelperPatch

    def self.included(base)
      base.extend(ClassMethods)
      base.send(:include, InstanceMethods)

      base.class_eval do

        alias_method_chain :text_field, :easy_extensions

      end
    end

    module ClassMethods
    end

    module InstanceMethods

      def text_field_with_easy_extensions(method, options = {})
        if @object.class.respond_to?(:translater_options) && @object.class.translater_options[:columns].include?(method.to_sym) && !@object.new_record?
          options[:class] ||= ''
          options[:class] << " easy-flag #{options[:locale] || User.current.current_language}"
          field = text_field_without_easy_extensions(method, options)
          field += @template.link_to('', @template.easy_translations_path(@object.class.name, @object, method), :remote => true, :class => 'icon-globe easy-translation-link', :title => l(:title_manage_easy_translations))
          @template.content_tag(:span, field, :class => "easy-translator-input-field #{options[:locale] || User.current.current_language}")
        else
          text_field_without_easy_extensions(method, options)
        end
      end

    end

  end
end
EasyExtensions::PatchManager.register_helper_patch 'ActionView::Helpers::FormBuilder', 'EasyPatch::FormHelperPatch'
