module EasyMoney
  module ProjectPatch

    def self.included(base)
      base.extend(ClassMethods)
      base.send(:include, InstanceMethods)

      base.class_eval do

        has_one :easy_money_project_cache, :class_name => 'EasyMoneyProjectCache', :dependent => :destroy

        has_one :expected_hours, :as => :entity, :class_name => 'EasyMoneyExpectedHours', :dependent => :destroy
        has_one :expected_payroll_expenses, :as => :entity, :class_name => 'EasyMoneyExpectedPayrollExpense', :dependent => :destroy

        has_many :expected_expenses, :as => :entity, :class_name => 'EasyMoneyExpectedExpense', :dependent => :destroy
        has_many :expected_revenues, :as => :entity, :class_name => 'EasyMoneyExpectedRevenue', :dependent => :destroy
        has_many :other_expenses, :as => :entity, :class_name => 'EasyMoneyOtherExpense', :dependent => :destroy
        has_many :other_revenues, :as => :entity, :class_name => 'EasyMoneyOtherRevenue', :dependent => :destroy
        has_many :easy_money_time_entry_expenses, :through => :time_entries
        has_many :easy_money_rates
        has_many :easy_money_settings_assoc, :class_name => "EasyMoneySettings", :foreign_key => "project_id", :dependent => :destroy

        after_save :copy_easy_money_rate_priority

        attr_accessor :inherit_easy_money_settings

        alias_method_chain :after_parent_changed, :easy_money

        safe_attributes 'inherit_easy_money_settings',
          :if => lambda {|project, user| project.new_record? }

        def easy_money
          @easy_money ||= EasyMoneyProject.new(self) if module_enabled?(:easy_money)
        end

        def easy_money_settings
          @easy_money_settings ||= EasyMoneySettingsResolver.new((EasyMoneySettings.global_settings_names + EasyMoneySettings.project_settings_names), self) if module_enabled?(:easy_money)
        end

        def copy_easy_money_settings_from_parent
          if inherit_easy_money_settings && module_enabled?(:easy_money) && parent && parent.module_enabled?(:easy_money)
            EasyMoneySettings.copy_to(parent, self)
            EasyMoneyRatePriority.rate_priorities_by_project(self).delete_all
            self.easy_money_rates.delete_all
            EasyMoneyRatePriority.rate_priorities_by_project(parent).copy_to(self)
            EasyMoneyRate.copy_to(parent, self)
          end
        end

        private

        def copy_easy_money_rate_priority
          mod = self.module_enabled?(:easy_money)

          if mod && EasyMoneyRatePriority.rate_priorities_by_project(self).blank?
            EasyMoneyRatePriority.rate_priorities_by_project(nil).copy_to(self)
          end
        end

        def copy_easy_money(project)
          EasyMoneySettings.copy_to(project, self)
          EasyMoneyRate.copy_to(project, self)
          EasyMoneyRatePriority.rate_priorities_by_project(project).copy_to(self)
          EasyMoneyTimeEntryExpense.update_project_time_entry_expenses(self)

          if project.easy_money_settings.show_expected?
            project.expected_expenses.each do |expected_expense|
              new_expected_expense = expected_expense.dup
              new_expected_expense.entity_id = self.id
              new_expected_expense.save
            end if project.expected_expenses.any?

            project.expected_revenues.each do |expected_revenue|
              new_expected_revenue = expected_revenue.dup
              new_expected_revenue.entity_id = self.id
              new_expected_revenue.save
            end if project.expected_revenues.any?
          end

          project.other_expenses.each do |other_expense|
            new_other_expense = other_expense.dup
            new_other_expense.entity_id = self.id
            new_other_expense.save
            new_other_expense.custom_values = other_expense.custom_values.collect {|v| v.dup} if other_expense.custom_values.any?
            new_other_expense.attachments = other_expense.attachments.collect {|a| a.dup} if other_expense.attachments.any?
          end if project.other_expenses.any?

          project.other_revenues.each do |other_revenue|
            new_other_revenue = other_revenue.dup
            new_other_revenue.entity_id = self.id
            new_other_revenue.save
            new_other_revenue.custom_values = other_revenue.custom_values.collect {|v| v.dup} if other_revenue.custom_values.any?
            new_other_revenue.attachments = other_revenue.attachments.collect {|a| a.dup} if other_revenue.attachments.any?
          end if project.other_expenses.any?

          if project.easy_money_settings.expected_payroll_expense_type == 'hours' && project.expected_hours
            new_expected_hours = project.expected_hours.dup
            new_expected_hours.entity_id = self.id
            new_expected_hours.save
          end

          if project.expected_payroll_expenses
            new_expected_payroll_expenses = project.expected_payroll_expenses.dup
            new_expected_payroll_expenses.entity_id = self.id
            new_expected_payroll_expenses.save
          end
        end

      end
    end

    module InstanceMethods

      def after_parent_changed_with_easy_money(parent_was)
        after_parent_changed_without_easy_money(parent_was)
        copy_easy_money_settings_from_parent
      end

      #      def easy_money_expected_revenue
      #        self.expected_revenue.price unless self.expected_revenue.nil?
      #      end
      #
      #      def easy_money_expected_revenue=(value)
      #        unless (self.id.blank?)
      #          e = self.expected_revenue || EasyMoneyExpectedRevenue.new(:entity_type => 'Project', :entity_id => self.id)
      #          e.price = value.blank? ? 0.0 : value
      #          e.save!
      #        end
      #      end
      #
      #      def easy_money_expected_expense
      #        self.expected_expense.price unless self.expected_expense.nil?
      #      end
      #
      #      def easy_money_expected_expense=(value)
      #        unless (self.id.blank?)
      #          e = self.expected_expense || EasyMoneyExpectedExpense.new(:entity_type => 'Project', :entity_id => self.id)
      #          e.price = value.blank? ? 0.0 : value
      #          e.save!
      #        end
      #      end
      #
      #      def easy_money_expected_hours
      #        self.expected_hours.hours unless self.expected_hours.nil?
      #      end
      #
      #      def easy_money_expected_hours=(value)
      #        unless (self.id.blank?)
      #          e = self.expected_hours || EasyMoneyExpectedHours.new(:entity_type => 'Project', :entity_id => self.id)
      #          e.hours = value.blank? ? 0 : value
      #          e.save!
      #        end
      #      end
    end

    module ClassMethods

    end

  end

end
EasyExtensions::PatchManager.register_model_patch 'Project', 'EasyMoney::ProjectPatch'
