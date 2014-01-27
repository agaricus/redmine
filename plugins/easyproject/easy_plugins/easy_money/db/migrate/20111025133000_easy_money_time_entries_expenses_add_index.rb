class EasyMoneyTimeEntriesExpensesAddIndex < ActiveRecord::Migration
  def self.up
    add_index :easy_money_time_entries_expenses, :time_entry_id, :name => 'idx_easy_money_time_entries_expenses_time_entry_id'
  end

  def self.down
    remove_index :easy_money_time_entries_expenses, :name =>  'idx_easy_money_time_entries_expenses_time_entry_id'
  end
end