class CreateEasyMoneyOtherRepeatingRevenues < ActiveRecord::Migration
  def self.up
    create_table :easy_money_other_repeating_revenues do |t|
      t.column :from, :date, { :null => false }
      t.column :to, :date, { :null => false }
      t.column :period, :string, { :null => false, :limit => 255 }
      t.column :name, :string, { :null => false, :limit => 255 }
      t.column :description, :text, { :null => true }
      t.column :price1, :decimal, { :null => true, :precision => 30, :scale => 2, :default => 0.0 }
      t.column :price2, :decimal, { :null => true, :precision => 30, :scale => 2, :default => 0.0 }
      t.column :vat, :decimal, { :null => true, :precision => 30, :scale => 2, :default => 0.0 }
      t.column :entity_type, :string, { :null => false, :limit => 255 }
      t.column :entity_id, :integer, { :null => false }
    end
  end

  def self.down
  end
end
