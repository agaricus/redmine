class ChangeSettingsCache < ActiveRecord::Migration
  def self.up
    EasyMoneySettings.update_all("value = 'daily'", "name = 'cache'")
  end

  def self.down
  end

end
