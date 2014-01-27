require 'easy_money/easy_money_base_model'

class EasyMoneyOtherRevenue < ActiveRecord::Base
  include EasyMoney::EasyMoneyBaseModel

  belongs_to :repeating_revenue, :class_name => "EasyMoneyOtherRepeatingRevenue", :foreign_key => 'repeating_id'

  after_create :send_notification_added
  after_update :send_notification_updated

  protected

  def send_notification_added
    if Setting.notified_events.include?('easy_money_other_revenue_added')
      EasyMoneyMailer.easy_money_other_revenue_added(self).deliver
    end
  end

  def send_notification_updated
    if Setting.notified_events.include?('easy_money_other_revenue_updated')
      EasyMoneyMailer.easy_money_other_revenue_updated(self).deliver
    end
  end

  def manage_permission
    :easy_money_manage_other_revenue
  end

end
