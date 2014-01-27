class ChangeDefaultUiThemeToEasy < ActiveRecord::Migration
  def up
    if s = Setting.find_by_name(:ui_theme)
      s.update_attribute(:value, 'easy_widescreen')
    else
      Setting.create(:name => 'ui_theme', :value => 'easy_widescreen')
    end
  end

  def down
    s = Setting.find_by_name(:ui_theme)
    s.update_attribute(:value, '')
  end
end
