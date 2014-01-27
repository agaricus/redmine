class AddEasyMoneySettings < ActiveRecord::Migration
  def self.up
    EasyMoneySettings.create :name => 'price_visibility', :project_id => nil, :value => 'price1'
    EasyMoneySettings.create :name => 'rate_type', :project_id => nil, :value => 'all'
    EasyMoneySettings.create :name => 'include_childs', :project_id => nil, :value => '1'
    EasyMoneySettings.create :name => 'expected_revenue', :project_id => nil, :value => '1'
    EasyMoneySettings.create :name => 'expected_expense', :project_id => nil, :value => '1'
    EasyMoneySettings.create :name => 'expected_hours', :project_id => nil, :value => '1'
    EasyMoneySettings.create :name => 'expected_count_price', :project_id => nil, :value => 'price1'
    EasyMoneySettings.create :name => 'expected_rate_type', :project_id => nil, :value => 'internal'
    EasyMoneySettings.create :name => 'vat', :project_id => nil, :value => '20'
  end

  def self.down
  end
end
