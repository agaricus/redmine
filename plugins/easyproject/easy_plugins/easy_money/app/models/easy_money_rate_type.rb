class EasyMoneyRateType < ActiveRecord::Base
  class STATUS
    ACTIVE     = 1
    ARCHIVED   = 9
  end

  self.table_name = 'easy_money_rate_types'
  
  default_scope :order => "#{EasyMoneyRateType.table_name}.position ASC"

  acts_as_list

  validates_presence_of :name

  scope :active, lambda { { :conditions => "#{EasyMoneyRateType.table_name}.status = #{EasyMoneyRateType::STATUS::ACTIVE}" } }
  scope :archived, lambda { { :conditions => "#{EasyMoneyRateType.table_name}.status = #{EasyMoneyRateType::STATUS::ARCHIVED}" } }

  before_save :set_default
  before_save :change_name

  def self.default
    find(:first, :conditions => { :is_default => true } )
  end

  def translated_name
    l("easy_money_rate_type.#{name}").html_safe
  end

  private

  def set_default
    if is_default? && is_default_changed?
      EasyMoneyRateType.update_all(:is_default => false)
    end
    return true
  end
  
  def change_name
    self.name = self.name.gsub(/[ ]/, '_').underscore unless self.name.blank?
    return true
  end

end
