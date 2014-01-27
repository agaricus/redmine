class MigrateTimeentrySettings < ActiveRecord::Migration
  def up
    s = Setting.where(:name => 'plugin_easy_extensions').first
    es1 = EasySetting.new(:name => 'spent_on_limit_before_today')
    es2 = EasySetting.new(:name => 'spent_on_limit_after_today')
    if s
      t = s['time_entry']
      if t
        es1.value = t['spent_on_limit_before_today']
        es2.value = t['spent_on_limit_after_today']
      end
      s.destroy
    end
    es1.value ||= ''
    es2.value ||= ''
    es1.save!
    es2.save!
  end

  def down
  end
end
