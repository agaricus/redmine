module EasyMoney
  module TimeEntryPatch

    def self.included(base)
      base.extend(ClassMethods)
      base.send(:include, InstanceMethods)

      base.class_eval do
        has_many :easy_money_time_entry_expenses, :class_name => 'EasyMoneyTimeEntryExpense', :foreign_key => 'time_entry_id', :dependent => :destroy

        scope :internal_rate, lambda {{:conditions => 'rate_type_id = 2'}}

        after_save :update_easy_money_time_entry_expense

        def update_easy_money_time_entry_expense
          EasyMoneyTimeEntryExpense.update_easy_money_time_entry_expense(self) if self.project.module_enabled?(:easy_money) && !self.new_record?
        end

        # Dynamically create method for *rates*.
        # * internal
        # * external
        EasyMoneyRateType.active.each_with_index do |rate_type, i|
          self.send(:define_method, EasyMoneyTimeEntryExpense::EASY_QUERY_PREFIX + rate_type.name) do
            if self.easy_money_time_entry_expenses[i]
              return self.easy_money_time_entry_expenses[i].price
            end
          end
        end if EasyMoneyRateType.table_exists?

      end
    end

    module InstanceMethods

    end

    module ClassMethods

    end

  end

end
EasyExtensions::PatchManager.register_model_patch 'TimeEntry', 'EasyMoney::TimeEntryPatch'
