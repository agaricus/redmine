class AddEasyMoneySettingCurrencyVisible < ActiveRecord::Migration
  def self.up
    EasyMoneySettings.create(:name => 'currency_visible', :value => nil)
  end

  def self.down
  end
end