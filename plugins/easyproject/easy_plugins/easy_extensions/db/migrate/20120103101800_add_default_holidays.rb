# encoding: utf-8
class AddDefaultHolidays < ActiveRecord::Migration
  def self.up
    cal = EasyUserWorkingTimeCalendar.find(:first, :conditions => {:is_default => true, :user_id => nil, :parent_id => nil})
    return unless cal

    EasyUserTimeCalendarHoliday.create(:calendar_id => cal.id, :name => 'Nový rok', :holiday_date => '2012-01-01'.to_date, :is_repeating => true)
    EasyUserTimeCalendarHoliday.create(:calendar_id => cal.id, :name => 'Velikonoční pondělí', :holiday_date => '2012-04-09'.to_date, :is_repeating => false)
    EasyUserTimeCalendarHoliday.create(:calendar_id => cal.id, :name => 'Svátek práce', :holiday_date => '2012-05-01'.to_date, :is_repeating => true)
    EasyUserTimeCalendarHoliday.create(:calendar_id => cal.id, :name => 'Den vítězství', :holiday_date => '2012-05-08'.to_date, :is_repeating => true)
    EasyUserTimeCalendarHoliday.create(:calendar_id => cal.id, :name => 'Den slovanských věrozvěstů Cyrila a Metoděje', :holiday_date => '2012-07-05'.to_date, :is_repeating => true)
    EasyUserTimeCalendarHoliday.create(:calendar_id => cal.id, :name => 'Den upálení mistra Jana Husa', :holiday_date => '2012-07-06'.to_date, :is_repeating => true)
    EasyUserTimeCalendarHoliday.create(:calendar_id => cal.id, :name => 'Den české státnosti', :holiday_date => '2012-09-28'.to_date, :is_repeating => true)
    EasyUserTimeCalendarHoliday.create(:calendar_id => cal.id, :name => 'Den vzniku samostatného československého státu', :holiday_date => '2012-10-28'.to_date, :is_repeating => true)
    EasyUserTimeCalendarHoliday.create(:calendar_id => cal.id, :name => 'Den boje za svobodu a demokracii', :holiday_date => '2012-11-17'.to_date, :is_repeating => true)
    EasyUserTimeCalendarHoliday.create(:calendar_id => cal.id, :name => 'Štědrý den', :holiday_date => '2012-12-24'.to_date, :is_repeating => true)
    EasyUserTimeCalendarHoliday.create(:calendar_id => cal.id, :name => '1. svátek vánoční', :holiday_date => '2012-12-25'.to_date, :is_repeating => true)
    EasyUserTimeCalendarHoliday.create(:calendar_id => cal.id, :name => '2. svátek vánoční', :holiday_date => '2012-12-26'.to_date, :is_repeating => true)
    EasyUserTimeCalendarHoliday.create(:calendar_id => cal.id, :name => 'Velikonoční pondělí', :holiday_date => '2013-04-01'.to_date, :is_repeating => false)
    EasyUserTimeCalendarHoliday.create(:calendar_id => cal.id, :name => 'Velikonoční pondělí', :holiday_date => '2014-04-21'.to_date, :is_repeating => false)
    EasyUserTimeCalendarHoliday.create(:calendar_id => cal.id, :name => 'Velikonoční pondělí', :holiday_date => '2015-04-06'.to_date, :is_repeating => false)
    EasyUserTimeCalendarHoliday.create(:calendar_id => cal.id, :name => 'Velikonoční pondělí', :holiday_date => '2016-03-28'.to_date, :is_repeating => false)
    EasyUserTimeCalendarHoliday.create(:calendar_id => cal.id, :name => 'Velikonoční pondělí', :holiday_date => '2017-04-17'.to_date, :is_repeating => false)
    EasyUserTimeCalendarHoliday.create(:calendar_id => cal.id, :name => 'Velikonoční pondělí', :holiday_date => '2018-04-02'.to_date, :is_repeating => false)
    EasyUserTimeCalendarHoliday.create(:calendar_id => cal.id, :name => 'Velikonoční pondělí', :holiday_date => '2019-04-22'.to_date, :is_repeating => false)
    EasyUserTimeCalendarHoliday.create(:calendar_id => cal.id, :name => 'Velikonoční pondělí', :holiday_date => '2020-04-13'.to_date, :is_repeating => false)
  end

  def self.down
  end
end