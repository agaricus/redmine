module EasyBudgetsheet
  module EntityAttributeHelperPatch

    def self.included(base)
      base.send(:include, InstanceMethods)

      base.class_eval do

        def format_html_budget_sheet_attribute(entity_class, attribute, unformatted_value, options={})
          value = format_html_time_entry_attribute(entity_class, attribute, unformatted_value, options)

          case attribute.name
          when :easy_billed
            if unformatted_value
              content_tag(:span, l(:general_text_Yes), :class => 'value_yes')
            else
              content_tag(:span, l(:general_text_No), :class => 'value_no')
            end
          else
            value
          end
        end

      end
    end

    module InstanceMethods

    end

  end

end
EasyExtensions::PatchManager.register_helper_patch 'EntityAttributeHelper', 'EasyBudgetsheet::EntityAttributeHelperPatch'
