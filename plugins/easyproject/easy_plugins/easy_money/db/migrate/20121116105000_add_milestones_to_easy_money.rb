class AddMilestonesToEasyMoney < ActiveRecord::Migration
  def self.up

    add_column :easy_money_other_expenses, :version_id, :integer, {:null => true}
    add_column :easy_money_other_revenues, :version_id, :integer, {:null => true}
    add_column :easy_money_expected_expenses, :version_id, :integer, {:null => true}
    add_column :easy_money_expected_revenues, :version_id, :integer, {:null => true}

  end

  def self.down

    remove_column :easy_money_other_expenses, :version_id
    remove_column :easy_money_other_revenues, :version_id
    remove_column :easy_money_expected_expenses, :version_id
    remove_column :easy_money_expected_revenues, :version_id

  end
end