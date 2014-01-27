class CreateEasyMoneyInitialRevenues < ActiveRecord::Migration
  def self.up
    create_table :easy_money_initial_revenues do |t|
      t.column :entity_type, :string, { :null => false, :limit => 255 }
      t.column :entity_id, :integer, { :null => false }
      t.column :price1, :decimal, { :null => true, :precision => 30, :scale => 2, :default => 0.0 }
      t.column :price2, :decimal, { :null => true, :precision => 30, :scale => 2, :default => 0.0 }
      t.column :vat, :decimal, { :null => true, :precision => 30, :scale => 2, :default => 0.0 }
      t.column :valid_from, :date, { :null => true }
      t.column :valid_to, :date, { :null => true }
    end
  end

  def self.down
  end
end
