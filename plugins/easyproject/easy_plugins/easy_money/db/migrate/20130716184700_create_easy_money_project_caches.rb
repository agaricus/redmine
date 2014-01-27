class CreateEasyMoneyProjectCaches < ActiveRecord::Migration
  def self.up

    create_table :easy_money_project_caches, :force => true do |t|

      t.column :project_id, :integer, {:null => false}

      t.column :sum_of_expected_hours, :float, { :null => false, :default => 0.0 }
      t.column :sum_of_expected_payroll_expenses, :float, { :null => false, :default => 0.0 }

      t.column :sum_of_expected_expenses_price_1, :float, { :null => false, :default => 0.0 }
      t.column :sum_of_expected_revenues_price_1, :float, { :null => false, :default => 0.0 }
      t.column :sum_of_other_expenses_price_1, :float, { :null => false, :default => 0.0 }
      t.column :sum_of_other_revenues_price_1, :float, { :null => false, :default => 0.0 }
      t.column :sum_of_expected_expenses_price_2, :float, { :null => false, :default => 0.0 }
      t.column :sum_of_expected_revenues_price_2, :float, { :null => false, :default => 0.0 }
      t.column :sum_of_other_expenses_price_2, :float, { :null => false, :default => 0.0 }
      t.column :sum_of_other_revenues_price_2, :float, { :null => false, :default => 0.0 }

      t.column :sum_of_time_entries_expenses_internal, :float, { :null => false, :default => 0.0 }
      t.column :sum_of_time_entries_expenses_external, :float, { :null => false, :default => 0.0 }

      t.column :sum_of_estimated_hours, :float, { :null => false, :default => 0.0 }
      t.column :sum_of_timeentries, :float, { :null => false, :default => 0.0 }

      t.column :sum_of_all_expected_expenses_price_1, :float, { :null => false, :default => 0.0 }
      t.column :sum_of_all_expected_revenues_price_1, :float, { :null => false, :default => 0.0 }
      t.column :sum_of_all_other_revenues_price_1, :float, { :null => false, :default => 0.0 }
      t.column :sum_of_all_expected_expenses_price_2, :float, { :null => false, :default => 0.0 }
      t.column :sum_of_all_expected_revenues_price_2, :float, { :null => false, :default => 0.0 }
      t.column :sum_of_all_other_revenues_price_2, :float, { :null => false, :default => 0.0 }

      t.column :sum_of_all_other_expenses_price_1_internal, :float, { :null => false, :default => 0.0 }
      t.column :sum_of_all_other_expenses_price_2_internal, :float, { :null => false, :default => 0.0 }
      t.column :sum_of_all_other_expenses_price_1_external, :float, { :null => false, :default => 0.0 }
      t.column :sum_of_all_other_expenses_price_2_external, :float, { :null => false, :default => 0.0 }

      t.column :expected_profit_price_1, :float, { :null => false, :default => 0.0 }
      t.column :expected_profit_price_2, :float, { :null => false, :default => 0.0 }
      t.column :other_profit_price_1_internal, :float, { :null => false, :default => 0.0 }
      t.column :other_profit_price_2_internal, :float, { :null => false, :default => 0.0 }
      t.column :other_profit_price_1_external, :float, { :null => false, :default => 0.0 }
      t.column :other_profit_price_2_external, :float, { :null => false, :default => 0.0 }

      t.column :average_hourly_rate_price_1, :float, { :null => false, :default => 0.0 }
      t.column :average_hourly_rate_price_2, :float, { :null => false, :default => 0.0 }
    end

    add_index :easy_money_project_caches, :project_id, :unique => true

  end

  def self.down

    drop_table :easy_money_project_caches

  end
end