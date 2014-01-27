class CreateEasyMoneyTimeEntries < ActiveRecord::Migration
  def self.up
    create_table :easy_money_time_entries_expenses do |t|
      t.column :time_entry_id, :integer, { :null => false }
      t.column :rate_type_id, :integer, { :null => false }
      t.column :price, :decimal, { :null => true, :precision => 30, :scale => 2, :default => 0.0 }
    end
  end

  def self.down
    drop_table :easy_money_time_entries_expenses
  end

end
