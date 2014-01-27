module EasyMoney
  module RedmineNotifiablePatch

    def self.included(base)
      base.extend(ClassMethods)
      base.send(:include, InstanceMethods)

      base.class_eval do

        class << self

          alias_method_chain :all, :easy_money

        end

      end
    end

    module InstanceMethods

    end

    module ClassMethods

      def all_with_easy_money
        n = all_without_easy_money
        n << Redmine::Notifiable.new('easy_money_expected_expense_added')
        n << Redmine::Notifiable.new('easy_money_expected_expense_updated')
        n << Redmine::Notifiable.new('easy_money_expected_revenue_added')
        n << Redmine::Notifiable.new('easy_money_expected_revenue_updated')
        n << Redmine::Notifiable.new('easy_money_other_expense_added')
        n << Redmine::Notifiable.new('easy_money_other_expense_updated')
        n << Redmine::Notifiable.new('easy_money_other_revenue_added')
        n << Redmine::Notifiable.new('easy_money_other_revenue_updated')
        n
      end

    end

  end

end
EasyExtensions::PatchManager.register_other_patch 'Redmine::Notifiable', 'EasyMoney::RedmineNotifiablePatch'
