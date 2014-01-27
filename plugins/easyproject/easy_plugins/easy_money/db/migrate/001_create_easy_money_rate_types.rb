class CreateEasyMoneyRateTypes < ActiveRecord::Migration
  def self.up
    create_table :easy_money_rate_types do |t|
      t.column :name, :string, { :null => false, :limit => 255 }
      t.column :description, :string, { :null => true, :length => 255 }
      t.column :status, :integer, { :null => false, :default => 1 }
      t.column :is_default, :boolean, { :null => false, :default => false }
      t.column :position, :integer, { :null => true }
    end
    
    EasyMoneyRateType.create :name => 'internal', :is_default => true, :status => EasyMoneyRateType::STATUS::ACTIVE
    EasyMoneyRateType.create :name => 'external', :is_default => false, :status => EasyMoneyRateType::STATUS::ACTIVE
  end

  def self.down
    drop_table :easy_money_rate_types
  end
end
