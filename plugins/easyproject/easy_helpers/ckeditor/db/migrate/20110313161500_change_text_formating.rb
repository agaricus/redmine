class ChangeTextFormating < ActiveRecord::Migration
  def self.up
    # Commented due to Easy redmine users
#    s = Setting.where(:name => 'text_formatting').first || Setting.new(:name => 'text_formatting')
#    s.value = 'HTML'
#    s.save!
  end

  def self.down
#    Setting.update_all("value = 'textile'", "name = 'text_formatting'")
  end

end
