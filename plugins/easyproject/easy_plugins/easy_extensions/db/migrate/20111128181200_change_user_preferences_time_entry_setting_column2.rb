class ChangeUserPreferencesTimeEntrySettingColumn2 < ActiveRecord::Migration
  def self.up
    UserPreference.update_all('user_time_entry_setting = \'hours\'', 'user_time_entry_setting = \'\' OR user_time_entry_setting IS NULL')
  end

  def self.down
  end
end
