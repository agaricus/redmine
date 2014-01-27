module EasyMoneyPatch
  module EasyBudgetSheetQueryPatch

    def self.included(base)
      base.send(:include, InstanceMethods)
      base.class_eval do

        alias_method_chain :available_columns, :easy_extensions

      end
    end

    module InstanceMethods

      def available_columns_with_easy_extensions
        c = available_columns_without_easy_extensions
        unless @new_columns_added
          EasyMoneyRateType.active.each do |rate_type|
            if User.current.allowed_to_globally?("easy_budgetsheet_view_#{rate_type.name}_rates".to_sym, {})
              sql = "(SELECT emte.price FROM #{EasyMoneyTimeEntryExpense.table_name} emte WHERE emte.rate_type_id = '#{rate_type.id}' AND emte.time_entry_id = #{TimeEntry.table_name}.id)"
              c << EasyQueryColumn.new((EasyMoneyTimeEntryExpense::EASY_QUERY_PREFIX + rate_type.name).to_sym, :sumable => :bottom, :sumable_sql => sql, :sortable => sql)
            end
          end

          @new_columns_added = true
        end

        return c
      end

    end

  end
end
EasyExtensions::PatchManager.register_model_patch 'EasyBudgetSheetQuery', 'EasyMoneyPatch::EasyBudgetSheetQueryPatch', :if => Proc.new{ Object.const_defined?(:EasyBudgetSheetQuery) }
