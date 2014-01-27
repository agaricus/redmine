class SetEasySyncMappings < ActiveRecord::Migration
  def self.up
    EasySyncMapping.create(:category => 'EasySyncMoney', :local_name => 'fakturoid_id', :remote_name => './id', :value_type => 'string')
    EasySyncMapping.create(:category => 'EasySyncMoney', :local_name => 'name', :remote_name => './client-name', :value_type => 'string')
    EasySyncMapping.create(:category => 'EasySyncMoney', :local_name => 'invoice_number', :remote_name => './number', :value_type => 'string')
    EasySyncMapping.create(:category => 'EasySyncMoney', :local_name => 'description', :remote_name => './note', :value_type => 'string')
    EasySyncMapping.create(:category => 'EasySyncMoney', :local_name => 'price1', :remote_name => './total', :value_type => 'decimal')
    EasySyncMapping.create(:category => 'EasySyncMoney', :local_name => 'price2', :remote_name => './subtotal', :value_type => 'decimal')
    EasySyncMapping.create(:category => 'EasySyncMoney', :local_name => 'spent_on', :remote_name => './paid-at', :value_type => 'date')
  end
  
  def self.down
    EasySyncMapping.find(:all, :conditions => {:category => 'EasyContact'}).each {|c| c.destroy}
  end
end