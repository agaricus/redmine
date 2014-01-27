class RepairExpectedPayrollExpenses < ActiveRecord::Migration
  def self.up
    EasyMoneySettings.update_all("value = 1", "name = 'expected_payroll_expense' AND value IS NULL")
  end

  def self.down
  end

end
