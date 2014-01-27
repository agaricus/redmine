class MigrateOldEasyprojectSettings2 < ActiveRecord::Migration
  def self.up
    Setting.update_all("name = 'plugin_easy_extensions'", "name = 'plugin_easyproject'")
  end

  def self.down
    Setting.update_all("name = 'plugin_easyproject'", "name = 'plugin_easy_extensions'")
  end
end
