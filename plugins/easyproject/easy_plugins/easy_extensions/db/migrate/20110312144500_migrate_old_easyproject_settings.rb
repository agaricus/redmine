class MigrateOldEasyprojectSettings < ActiveRecord::Migration
  def self.up
    Setting.update_all("name = 'plugin_easyproject'", "name = 'plugin_easy_plugin'") if !Setting.find_by_name('plugin_easyproject')
  end

  def self.down
    Setting.update_all("name = 'plugin_easy_plugin'", "name = 'plugin_easyproject'") if !Setting.find_by_name('plugin_easy_plugin')
  end

end
