class AddDefaultEasyUserWorkingTimeCalendar < ActiveRecord::Migration
  def self.up
    EasyUserWorkingTimeCalendar.create :name => 'Standard', :builtin => true, :is_default => true, :default_working_hours => 8.0, :first_day_of_week => 1
  end

  def self.down
  end

end