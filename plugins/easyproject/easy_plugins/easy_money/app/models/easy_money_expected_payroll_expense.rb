class EasyMoneyExpectedPayrollExpense < ActiveRecord::Base

  belongs_to :entity, :polymorphic => true

  validates_presence_of :entity_type
  validates_presence_of :entity_id
  validates_numericality_of :price, :allow_nil => false, :only_integer => false, :greater_than_or_equal_to => 0.0
  
end
