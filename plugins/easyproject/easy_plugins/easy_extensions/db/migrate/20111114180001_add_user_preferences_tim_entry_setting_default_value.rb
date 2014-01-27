class AddUserPreferencesTimEntrySettingDefaultValue < ActiveRecord::Migration
  def self.up
    UserPreference.update_all('user_time_entry_setting = \'hours\'', 'user_time_entry_setting = \'\' OR user_time_entry_setting IS NULL')

    change_column :user_preferences, :user_time_entry_setting, :string, { :null => false, :default => 'hours' }
  end

  def self.down
    change_column :user_preferences, :user_time_entry_setting, :string, :null => true
  end
end
