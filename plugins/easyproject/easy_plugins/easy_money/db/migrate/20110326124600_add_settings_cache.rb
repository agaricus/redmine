class AddSettingsCache < ActiveRecord::Migration
  def self.up
    EasyMoneySettings.create :name => 'cache', :project_id => nil, :value => 'hit'
  end

  def self.down
  end

end
