class ChangeUserPreferenceOtherToLongText < ActiveRecord::Migration
  def up
    adapter_name = UserPreference.connection_config[:adapter]
    case adapter_name.downcase
    when 'mysql', 'mysql2'
      change_column :user_preferences, :others, :text, {:limit => 4294967295, :default => nil}
    end
  end

  def down
  end
end
