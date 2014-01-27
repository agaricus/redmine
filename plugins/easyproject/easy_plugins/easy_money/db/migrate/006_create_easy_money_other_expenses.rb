class CreateEasyMoneyOtherExpenses < ActiveRecord::Migration
  def self.up
    create_table :easy_money_other_expenses do |t|
      t.column :spent_on, :date, { :null => false }
      t.column :name, :string, { :null => false, :limit => 255 }
      t.column :description, :text, { :null => true }
      t.column :price1, :decimal, { :null => true, :precision => 30, :scale => 2, :default => 0.0 }
      t.column :price2, :decimal, { :null => true, :precision => 30, :scale => 2, :default => 0.0 }
      t.column :vat, :decimal, { :null => true, :precision => 30, :scale => 2, :default => 0.0 }
      t.column :entity_type, :string, { :null => false, :limit => 255 }
      t.column :entity_id, :integer, { :null => false }
      t.column :repeating_id, :integer, { :null => true }
    end
  end

  def self.down
    drop_table :easy_money_other_expenses
  end
end
