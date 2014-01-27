class AddUserPreferencesTimeEntrySetting < ActiveRecord::Migration
  def self.up
    add_column :user_preferences, :user_time_entry_setting, :string, :null => true
  end

  def self.down
    remove_column :user_preferences, :user_time_entry_setting
  end
end
