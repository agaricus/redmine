class CreateEasyMoneyExpectedHours < ActiveRecord::Migration
  def self.up
    create_table :easy_money_expected_hours do |t|
      t.column :entity_type, :string, { :null => false, :limit => 255 }
      t.column :entity_id, :integer, { :null => false }
      t.column :hours, :integer, { :null => false, :default => 0 }
    end
  end

  def self.down
    drop_table :easy_money_expected_hours
  end
end
