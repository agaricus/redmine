class ChangeColumnSpentOn < ActiveRecord::Migration
  def self.up
    change_column :easy_money_other_expenses, :spent_on, :date, { :null => true }
    change_column :easy_money_other_revenues, :spent_on, :date, { :null => true }
  end

  def self.down
  end
end
