module EasyMoney
  module VersionPatch

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

        has_many :time_entries, :through => :fixed_issues
        has_many :easy_money_time_entry_expenses, :through => :time_entries

        def easy_money
          @easy_money ||= EasyMoneyVersion.new(self) if project.module_enabled?(:easy_money)
          @easy_money
        end

      end
    end

    module InstanceMethods

    end

    module ClassMethods

    end

  end

end
EasyExtensions::PatchManager.register_model_patch 'Version', 'EasyMoney::VersionPatch'
