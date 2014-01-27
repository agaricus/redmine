module EasyMoney
  module IssuePatch

    def self.included(base)
      base.extend(ClassMethods)
      base.send(:include, InstanceMethods)

      base.class_eval do

        has_one :expected_hours, :as => :entity, :class_name => 'EasyMoneyExpectedHours', :dependent => :destroy
        has_one :expected_payroll_expenses, :as => :entity, :class_name => 'EasyMoneyExpectedPayrollExpense', :dependent => :destroy
        has_many :expected_expenses, :as => :entity, :class_name => 'EasyMoneyExpectedExpense', :dependent => :destroy
        has_many :expected_revenues, :as => :entity, :class_name => 'EasyMoneyExpectedRevenue', :dependent => :destroy
        has_many :other_expenses, :as => :entity, :class_name => 'EasyMoneyOtherExpense', :dependent => :destroy
        has_many :other_revenues, :as => :entity, :class_name => 'EasyMoneyOtherRevenue', :dependent => :destroy
        has_many :easy_money_time_entry_expenses, :through => :time_entries

        def easy_money
          @easy_money ||= EasyMoneyIssue.new(self) if project.module_enabled?(:easy_money)
          @easy_money
        end

        def easy_money_enabled?
          @easy_money_enabled ||= (EasyMoneySettings.find_settings_by_name(:use_easy_money_for_issues, self.project) == '1')
        end

        def easy_money_visible?(user=User.current)
          actions = [
            :easy_money_show_expected_revenue,
            :easy_money_show_expected_payroll_expense,
            :easy_money_show_expected_expense, 
            :easy_money_show_expected_profit,
            :easy_money_show_expected_payroll_expense,
            :easy_money_show_other_revenue,
            :easy_money_show_time_entry_expenses,
            :easy_money_show_other_expense,
            :easy_money_show_other_profit,
            :easy_money_show_time_entry_expenses
          ]
          user.allowed_to_at_least_one_action?(actions, self.project)
        end

        def easy_money_editable?(user=User.current)
          actions = [
            :easy_money_manage_expected_revenue,
            :easy_money_manage_expected_payroll_expense,
            :easy_money_manage_expected_expense, 
            :easy_money_manage_expected_payroll_expense,
            :easy_money_manage_other_revenue
          ]
          user.allowed_to_at_least_one_action?(actions, self.project)
        end

      end
    end

    module InstanceMethods

    end

    module ClassMethods

    end

  end

end
EasyExtensions::PatchManager.register_model_patch 'Issue', 'EasyMoney::IssuePatch'
