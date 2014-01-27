class ChangeDefaultLang < ActiveRecord::Migration
  def up
    s = Setting.where(:name => 'default_language').first || Setting.new(:name => 'default_language')
    s.value = 'en'
    s.save!
  end

  def down
  end
end
