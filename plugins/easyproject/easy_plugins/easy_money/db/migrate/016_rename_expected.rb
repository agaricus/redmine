class RenameExpected < ActiveRecord::Migration

  def self.up
    drop_table :easy_money_expected_expenses
    rename_table :easy_money_initial_expenses, :easy_money_expected_expenses
    remove_column :easy_money_expected_expenses, :valid_from
    remove_column :easy_money_expected_expenses, :valid_to
    add_column :easy_money_expected_expenses, :spent_on, :date, { :null => true }

    drop_table :easy_money_expected_revenues
    rename_table :easy_money_initial_revenues, :easy_money_expected_revenues
    remove_column :easy_money_expected_revenues, :valid_from
    remove_column :easy_money_expected_revenues, :valid_to
    add_column :easy_money_expected_revenues, :spent_on, :date, { :null => true }
  end

  def self.down
  end

end
