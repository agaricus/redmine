module EasyBudgetsheet
  module EasyTimeEntryBaseQueryPatch

    def self.included(base)
      base.extend(ClassMethods)
      base.send(:include, InstanceMethods)

      base.class_eval do

        alias_method_chain :available_columns, :easy_budgetsheet
        alias_method_chain :available_filters, :easy_budgetsheet

        def sql_for_easy_is_billable_field(field, operator, value)
          db_table = TimeEntry.table_name
          db_field = 'easy_is_billable'

          sql = sql_for_field(field, '=', value, db_table, db_field)
          sql << " OR #{db_table}.#{db_field} IS NULL" if Array(value).include?('0')

          return sql
        end

      end
    end

    module InstanceMethods

      def available_columns_with_easy_budgetsheet
        c = available_columns_without_easy_budgetsheet
        if EasySetting.value('show_billable_things') && !@new_columns_added_easy_budgetsheet

          c << EasyQueryColumn.new(:easy_is_billable, :sortable => "#{TimeEntry.table_name}.easy_is_billable", :groupable => true)
          c << EasyQueryColumn.new(:easy_billed, :sortable => "#{TimeEntry.table_name}.easy_billed", :groupable => true)

          @new_columns_added_easy_budgetsheet = true
        end

        return c
      end

      def available_filters_with_easy_budgetsheet
        f = available_filters_without_easy_budgetsheet
        if EasySetting.value('show_billable_things') && !@new_filters_added_easy_budgetsheet
          
          group = l(:label_filter_group_easy_time_entry_query)

          f['easy_is_billable'] = { :type => :list, :values => [[l(:general_text_yes), '1'], [l(:general_text_no), '0']], :order => 30, :group => group }
          f['easy_billed'] = { :type => :list, :values => [[l(:general_text_yes), '1'], [l(:general_text_no), '0']], :order => 31, :group => group }

          @new_filters_added_easy_budgetsheet = true
        end

        return f
      end

    end

    module ClassMethods

    end

  end

end
EasyExtensions::PatchManager.register_model_patch 'EasyTimeEntryBaseQuery', 'EasyBudgetsheet::EasyTimeEntryBaseQueryPatch'
