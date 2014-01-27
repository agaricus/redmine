class SetEasySyncPohodaExpenses < ActiveRecord::Migration
  def self.up
    EasySyncMapping.create(:category => 'EasySyncPohodaExpenses', :local_name => 'pohoda_id', :remote_id => 2, :value_type => 'string')
    EasySyncMapping.create(:category => 'EasySyncPohodaExpenses', :local_name => 'name', :remote_id => 3, :value_type => 'string')
    EasySyncMapping.create(:category => 'EasySyncPohodaExpenses', :local_name => 'spent_on', :remote_id => 1, :value_type => 'date')
    EasySyncMapping.create(:category => 'EasySyncPohodaExpenses', :local_name => 'price1', :remote_id => 7, :value_type => 'decimal')
    EasySyncMapping.create(:category => 'EasySyncPohodaExpenses', :local_name => 'price2', :remote_id => 7, :value_type => 'decimal')
  end
  
  def self.down
    EasySyncMapping.find(:all, :conditions => {:category => 'EasySyncPohodaExpenses'}).each {|c| c.destroy}
  end
end