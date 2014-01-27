class SetDefaultCurrencyAndFormat < ActiveRecord::Migration

  def self.up
    currency_field        = 'currency'
    currency_format_field = 'currency_format'

    EasyMoneySettings.where(:name => currency_field, :value => nil).delete_all

    if EasyMoneySettings.find_settings_by_name(currency_field).blank?
      setting = EasyMoneySettings.new
      setting.name  = currency_field
      setting.value = '$'
      setting.save
    end

    if EasyMoneySettings.find_settings_by_name(currency_format_field).blank?
      setting = EasyMoneySettings.new
      setting.name  = currency_format_field
      setting.value = '%n %u'
      setting.save
    end
  end

  def self.down
  end

end
