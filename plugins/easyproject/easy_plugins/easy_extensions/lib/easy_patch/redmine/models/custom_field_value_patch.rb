module EasyPatch
  module CustomFieldValuePatch

    def self.included(base)
      base.send(:include, InstanceMethods)

      base.class_eval do
        
        alias_method_chain :visible?, :easy_extensions
        
        def cast_value(cf = nil)
          cf ||= self.custom_field
          cf.cast_value(self.value)
        end

        def selected_entities(release_cache = false)
          return @selected_entities if @selected_entities && !release_cache
          return [] if self.custom_field.field_format != 'easy_lookup'
          return [] if self.custom_field.settings.blank?
          return [] if !self.custom_field.settings.key?('entity_type')
          ent_class = self.custom_field.settings['entity_type'].constantize rescue nil;
          return [] if ent_class.nil?
          sel_ids = self.cast_value
          return [] if sel_ids.blank?
          

          m = "find_#{self.custom_field.settings['entity_type'].underscore}_selected_entities"
          if respond_to?(m)
            @selected_entities = send(m, sel_ids)
          else
            @selected_entities = ent_class.where({:id => sel_ids}).all
          end

          @selected_entities
        end

        def validate_value_with_custom_field_value
          case self.custom_field.field_format
          when 'autoincrement'
            self.customized.errors.add(:base, self.custom_field.name + ' ' + ::I18n.t('activerecord.errors.messages.taken')) unless self.autoincrement_number_valid?
          end
        end

        def autoincrement_number_valid?
          return false if self.value.blank?

          return true if CustomValue.where(:customized_type => self.customized.class.name).
            where(:customized_id => self.customized.id).
            where(:custom_field_id => self.custom_field.id).
            where(:value => self.value).count == 1

          settings = self.custom_field.settings || {}
          scope = CustomValue.joins(:custom_field).where(["#{CustomValue.table_name}.custom_field_id = ?", self.custom_field.id]).
            where(["#{CustomField.table_name}.type = ?", self.custom_field.type])

          if self.custom_field.type == 'IssueCustomField' && (settings['per_project'] == '1' || settings['per_tracker'] == '1')
            scope = scope.joins("INNER JOIN #{Issue.table_name} ON #{Issue.table_name}.id = #{CustomValue.table_name}.customized_id")
            if settings['per_project'] == '1'
              scope = scope.where(["#{Issue.table_name}.project_id = ?", self.customized.project_id])
            end
            if settings['per_tracker'] == '1'
              scope = scope.where(["#{Issue.table_name}.tracker_id = ?", self.customized.tracker_id])
            end
          end

          scope = scope.where(["#{CustomValue.table_name}.value = ?", self.value])
          scope.count == 0
        end

      end
    end

    module InstanceMethods
      
      def visible_with_easy_extensions?
        if self.custom_field.field_format == 'easy_rating'
          User.current && User.current.admin?
        else
          visible_without_easy_extensions?
        end
      end
      
    end
  end
end
EasyExtensions::PatchManager.register_model_patch 'CustomFieldValue', 'EasyPatch::CustomFieldValuePatch'
