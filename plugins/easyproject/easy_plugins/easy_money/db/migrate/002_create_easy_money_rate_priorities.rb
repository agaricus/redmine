class CreateEasyMoneyRatePriorities < ActiveRecord::Migration
  def self.up
    create_table :easy_money_rate_priorities do |t|
      t.column :project_id, :integer, { :null => true }
      t.column :rate_type_id, :integer, { :null => false }
      t.column :entity_type, :string, { :null => false, :limit => 255 }
      t.column :position, :integer, { :null => true }
    end
    
    EasyMoneyRateType.active.each do |rate_type|
      EasyMoneyRatePriority.create :project_id => nil, :rate_type_id => rate_type.id, :entity_type => 'TimeEntryActivity'
      EasyMoneyRatePriority.create :project_id => nil, :rate_type_id => rate_type.id, :entity_type => 'Role'
      EasyMoneyRatePriority.create :project_id => nil, :rate_type_id => rate_type.id, :entity_type => 'User'
    end
  end

  def self.down
    drop_table :easy_money_rate_priorities
  end
end
