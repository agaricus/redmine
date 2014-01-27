class AddDefaultCalendarToAllUsers < ActiveRecord::Migration
  def self.up
    default_calendar = EasyUserWorkingTimeCalendar.find(:first, :conditions => {:user_id => nil, :parent_id => nil, :is_default => true})

    User.all.each do |user|
      default_calendar.assign_to_user(user, true)
    end if default_calendar
    
  end
  
  def self.down
  end
end