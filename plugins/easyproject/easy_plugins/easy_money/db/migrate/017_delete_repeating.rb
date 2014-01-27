class DeleteRepeating < ActiveRecord::Migration
  def self.up
    drop_table :easy_money_other_repeating_expenses
    drop_table :easy_money_other_repeating_revenues

    remove_column :easy_money_other_expenses, :repeating_id
    remove_column :easy_money_other_revenues, :repeating_id
  end

  def self.down
  end
end
