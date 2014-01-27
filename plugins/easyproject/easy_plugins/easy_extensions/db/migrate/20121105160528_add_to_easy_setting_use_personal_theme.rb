class AddToEasySettingUsePersonalTheme < ActiveRecord::Migration
  def up
  	EasySetting.create(:name => 'use_personal_theme', :value => false)
  end

  def down
  	EasySetting.where(:name => 'use_personal_theme').destroy_all
  end
end
