module EasyPatch

  module ActsAsCustomizableInstanceMethodsPatch

    def self.included(base)
      base.send(:include, InstanceMethods)

      base.class_eval do

        alias_method_chain :custom_fields=, :easy_extensions
        alias_method_chain :custom_field_values=, :easy_extensions
        alias_method_chain :save_custom_field_values, :easy_extensions
        alias_method_chain :validate_custom_field_values, :easy_extensions

        def custom_field_value_for(c)
          field_id = (c.is_a?(CustomField) ? c.id : c.to_i)
          custom_field_values.detect {|v| v.custom_field_id == field_id }
        end

        def custom_field_casted_value(c)
          field_id = (c.is_a?(CustomField) ? c.id : c.to_i)
          custom_field_values.detect {|v| v.custom_field_id == field_id }.try(:cast_value)
        end

        def format_custom_value_before_save(custom_field, value)
          case custom_field.field_format.to_sym
          when :datetime
            custom_field.cast_value(value)
          else
            value
          end
        end

      end

    end

    module InstanceMethods

      def custom_fields_with_easy_extensions=(values)
        values_to_hash = values.inject({}) do |hash, v|
          v = v.stringify_keys
          if v.has_key?('value')
            if !v['id'].blank?
              hash[v['id']] = v['value']
            elsif !v['internal_name'].blank?
              hash[v['internal_name']] = v['value']
            end
          end
          hash
        end
        self.custom_field_values = values_to_hash
      end

      def custom_field_values_with_easy_extensions=(values)
        values = values.stringify_keys

        custom_field_values.each do |custom_field_value|
          id_key = custom_field_value.custom_field_id.to_s
          internal_name_key = custom_field_value.custom_field.internal_name.to_s
          if values.has_key?(id_key) || values.has_key?(internal_name_key)
            value = values[id_key] || values[internal_name_key]
            if value.is_a?(Array)
              value = value.reject(&:blank?).uniq
              if value.empty?
                value << ''
              end
            end
            value = format_custom_value_before_save(custom_field_value.custom_field, value)
            custom_field_value.value = value
          end
        end
        @custom_field_values_changed = true
      end

      def save_custom_field_values_with_easy_extensions
        target_custom_values = []
        custom_field_values.each do |custom_field_value|
          if custom_field_value.value.is_a?(Array)
            custom_field_value.value.each do |v|
              target = custom_values.detect {|cv| cv.custom_field == custom_field_value.custom_field && cv.value == v}
              target ||= custom_values.build(:customized => self, :custom_field => custom_field_value.custom_field, :value => v)
              target_custom_values << target
            end
          else
            target = custom_values.detect {|cv| cv.custom_field == custom_field_value.custom_field}
            target ||= custom_values.build(:customized => self, :custom_field => custom_field_value.custom_field)
            target.value = target.default_value || custom_field_value.value
            target_custom_values << target
          end
        end
        self.custom_values = target_custom_values
        custom_values.each(&:save)
        @custom_field_values_changed = false
        true
      end

      def validate_custom_field_values_with_easy_extensions
        validate_custom_field_values_without_easy_extensions
        if new_record? || custom_field_values_changed?
          custom_field_values.each(&:validate_value_with_custom_field_value)
        end
      end

    end

  end

  module ActsAsCustomizableClassMethodsPatch

    def self.included(base)
      base.send(:include, ClassMethods)

      base.class_eval do

        alias_method_chain :acts_as_customizable, :easy_extensions

      end
    end

    module ClassMethods

      def acts_as_customizable_with_easy_extensions(options={})
        acts_as_customizable_without_easy_extensions(options)

        has_one :easy_global_rating, :as => :customized

      end

    end

  end

end
EasyExtensions::PatchManager.register_patch_to_be_first 'Redmine::Acts::Customizable::InstanceMethods', 'EasyPatch::ActsAsCustomizableInstanceMethodsPatch', :first => true
EasyExtensions::PatchManager.register_patch_to_be_first 'Redmine::Acts::Customizable::ClassMethods', 'EasyPatch::ActsAsCustomizableClassMethodsPatch', :first => true
