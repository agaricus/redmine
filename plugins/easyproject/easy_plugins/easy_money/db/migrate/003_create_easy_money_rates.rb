class CreateEasyMoneyRates < ActiveRecord::Migration
  def self.up
    create_table :easy_money_rates do |t|
      t.column :project_id, :integer, { :null => true }
      t.column :rate_type_id, :integer, { :null => false }
      t.column :entity_type, :string, { :null => false, :limit => 255 }
      t.column :entity_id, :integer, { :null => false }
      t.column :unit_rate, :decimal, { :null => false, :precision => 30, :scale => 2, :default => 0.0 }
      t.column :valid_from, :date, { :null => true }
      t.column :valid_to, :date, { :null => true }
    end
  end

  def self.down
    drop_table :easy_money_rates
  end
end
