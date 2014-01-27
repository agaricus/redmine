class FixWorkingTimeCalendars < ActiveRecord::Migration
  def self.up
    EasyUserWorkingTimeCalendar.where("#{EasyUserWorkingTimeCalendar.table_name}.user_id IS NOT NULL AND #{EasyUserWorkingTimeCalendar.table_name}.parent_id IS NOT NULL").update_all(:is_default => false)
    EasyUserWorkingTimeCalendar.where("#{EasyUserWorkingTimeCalendar.table_name}.user_id IS NOT NULL AND #{EasyUserWorkingTimeCalendar.table_name}.parent_id IS NOT NULL").update_all(:builtin => false)

    if EasyUserWorkingTimeCalendar.where(:user_id => nil, :parent_id => nil).where(["#{EasyUserWorkingTimeCalendar.table_name}.is_default = ?", true]).count > 1
      EasyUserWorkingTimeCalendar.where(:user_id => nil, :parent_id => nil).where(["#{EasyUserWorkingTimeCalendar.table_name}.is_default = ?", true]).update_all(:is_default => false)
    end

    if EasyUserWorkingTimeCalendar.where(:user_id => nil, :parent_id => nil).where(["#{EasyUserWorkingTimeCalendar.table_name}.is_default = ?", true]).count == 0
      if c = EasyUserWorkingTimeCalendar.where(:user_id => nil, :parent_id => nil).first
        c.is_default = true
        c.save!
      end
    end

    User.includes(:working_time_calendar).all.each do |user|
      next unless user.working_time_calendar.nil?
      user.send(:create_easy_user_working_time_calendar_from_default)
    end
  end

  def self.down
    
  end

end