require 'easy_money/easy_money_base_model'

class EasyMoneyExpectedExpense < ActiveRecord::Base
  include EasyMoney::EasyMoneyBaseModel

  after_create :send_notification_added
  after_update :send_notification_updated

  protected

  def send_notification_added
    if Setting.notified_events.include?('easy_money_expected_expense_added')
      EasyMoneyMailer.easy_money_expected_expense_added(self).deliver
    end
  end

  def send_notification_updated
    if Setting.notified_events.include?('easy_money_expected_expense_updated')
      EasyMoneyMailer.easy_money_expected_expense_updated(self).deliver
    end
  end

  def self.manage_permission
    :easy_money_manage_expected_expense
  end

end
