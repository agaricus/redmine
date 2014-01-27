class AddEasyExternalIdToEasyMoney < ActiveRecord::Migration
  def self.up

    add_column :easy_money_expected_expenses, :easy_external_id, :string, {:null => true, :limit => 255}
    add_column :easy_money_expected_hours, :easy_external_id, :string, {:null => true, :limit => 255}
    add_column :easy_money_expected_payroll_expenses, :easy_external_id, :string, {:null => true, :limit => 255}
    add_column :easy_money_expected_revenues, :easy_external_id, :string, {:null => true, :limit => 255}
    add_column :easy_money_other_expenses, :easy_external_id, :string, {:null => true, :limit => 255}
    add_column :easy_money_other_revenues, :easy_external_id, :string, {:null => true, :limit => 255}

  end

  def self.down

    remove_column :easy_money_expected_expenses, :easy_external_id
    remove_column :easy_money_expected_hours, :easy_external_id
    remove_column :easy_money_expected_payroll_expenses, :easy_external_id
    remove_column :easy_money_expected_revenues, :easy_external_id
    remove_column :easy_money_other_expenses, :easy_external_id
    remove_column :easy_money_other_revenues, :easy_external_id
    
  end
end