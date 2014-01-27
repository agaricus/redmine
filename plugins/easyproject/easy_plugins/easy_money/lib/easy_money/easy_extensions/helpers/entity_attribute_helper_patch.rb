module EasyMoney
  module EntityAttributeHelperPatch

    def self.included(base)
      base.send(:include, InstanceMethods)

      base.class_eval do

        def format_html_easy_money_attribute(entity_class, attribute, unformatted_value, options={})
          value = format_entity_attribute(entity_class, attribute, unformatted_value, options)

          if (attribute.is_a?(EasyEntityCustomAttribute) && options[:entity])
            cv = options[:entity].visible_custom_field_values.detect {|v| v.custom_field_id == attribute.custom_field.id}
            show_value(cv, options)
          else
            case attribute.name
            when :price1, :price2
              if options[:entity]
                format_easy_money_price(value, options[:entity].project, :round => true)
              else
                format_easy_money_price(value, options[:project], :round => true)
                # format_price(value)
              end
            when :vat
              if options[:entity] && options[:entity].price1 > 0.0 && options[:entity].price2 > 0.0
                format_easy_money_price(options[:entity].price1 - options[:entity].price2, options[:entity].project, :round => true)
              else
                format_price(0.0)
              end
            when :project
              link_to_project(value) if value
            when :issue
              link_to_issue(value) if value
            when :version
              link_to_version(value) if value
            else
              h(value)
            end
          end
        end

        def format_html_easy_money_expected_expense_attribute(entity_class, attribute, unformatted_value, options={})
          format_html_easy_money_attribute(entity_class, attribute, unformatted_value, options)
        end

        def format_html_easy_money_expected_revenue_attribute(entity_class, attribute, unformatted_value, options={})
          format_html_easy_money_attribute(entity_class, attribute, unformatted_value, options)
        end

        def format_html_easy_money_other_expense_attribute(entity_class, attribute, unformatted_value, options={})
          format_html_easy_money_attribute(entity_class, attribute, unformatted_value, options)
        end

        def format_html_easy_money_other_revenue_attribute(entity_class, attribute, unformatted_value, options={})
          format_html_easy_money_attribute(entity_class, attribute, unformatted_value, options)
        end

        def format_html_easy_money_project_cache_attribute(entity_class, attribute, unformatted_value, options={})
          value = format_entity_attribute(entity_class, attribute, unformatted_value, options)

          if (attribute.is_a?(EasyEntityCustomAttribute) && options[:entity])
            cv = options[:entity].visible_custom_field_values.detect {|v| v.custom_field_id == attribute.custom_field.id}
            show_value(cv, options)
          else
            case attribute.name
            when :sum_of_expected_payroll_expenses, :sum_of_expected_expenses_price_1, :sum_of_expected_revenues_price_1,
                :sum_of_other_expenses_price_1, :sum_of_other_revenues_price_1, :sum_of_expected_expenses_price_2,
                :sum_of_expected_revenues_price_2, :sum_of_other_expenses_price_2, :sum_of_other_revenues_price_2,
                :sum_of_time_entries_expenses_internal, :sum_of_time_entries_expenses_external, :sum_of_all_expected_expenses_price_1,
                :sum_of_all_expected_revenues_price_1, :sum_of_all_other_revenues_price_1, :sum_of_all_expected_expenses_price_2,
                :sum_of_all_expected_revenues_price_2, :sum_of_all_other_revenues_price_2, :sum_of_all_other_expenses_price_1_internal,
                :sum_of_all_other_expenses_price_2_internal, :sum_of_all_other_expenses_price_1_external, :sum_of_all_other_expenses_price_2_external,
                :expected_profit_price_1, :expected_profit_price_2, :other_profit_price_1_internal, :other_profit_price_2_internal,
                :other_profit_price_1_external, :other_profit_price_2_external, :average_hourly_rate_price_1, :average_hourly_rate_price_2
              if options[:entity]
                format_easy_money_price(value, options[:entity].project)
              else
                format_price(value)
              end
            when :sum_of_expected_hours, :sum_of_estimated_hours, :sum_of_timeentries
              format_hours(value)
            when :project, :parent_project, :main_project
              link_to(h(value), link_to_project_with_easy_money(value)) if value
            else
              h(value)
            end
          end
        end

      end
    end

    module InstanceMethods

    end

  end

end
EasyExtensions::PatchManager.register_helper_patch 'EntityAttributeHelper', 'EasyMoney::EntityAttributeHelperPatch'
