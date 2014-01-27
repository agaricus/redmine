module EasyPatch

  module SafeAttributesClassMethodsPatch

    def self.included(base)
      base.class_eval do

        def delete_safe_attribute(attr_name)
          @safe_attributes.delete_if{|k, v| k == [attr_name]}
          @safe_attributes.each{|k, v| k.delete_if{|n| n == attr_name}}
        end

      end

    end
  end

  module SafeAttributesPatch

    def self.included(base)
      base.send(:include, InstanceMethods)
      base.class_eval do
        alias_method_chain :safe_attribute_names , :easy_extensions
      end

    end

    module InstanceMethods

      # Adds same cache for User.current as for user==nil
      def safe_attribute_names_with_easy_extensions(user=nil)
        return @safe_attribute_names if @safe_attribute_names && user == User.current

        res = safe_attribute_names_without_easy_extensions(user)
        @safe_attribute_names = res if user == User.current
        res
      end

    end
  end

end
EasyExtensions::PatchManager.register_other_patch 'Redmine::SafeAttributes::ClassMethods', 'EasyPatch::SafeAttributesClassMethodsPatch'
EasyExtensions::PatchManager.register_other_patch 'Redmine::SafeAttributes', 'EasyPatch::SafeAttributesPatch'
