require 'easy_extensions/timelog/timelog_calendar'

class EpmTimelogCalendar < EasyPageModule

  def category_name
    @category_name ||= 'timelog'
  end

  def get_show_data(settings, user, page_context = {})
    start_date = settings['start_date'].blank? ? Date.today : settings['start_date'].to_date
    calendar = EasyExtensions::Timelog::Calendar.new(start_date, user.language, (settings['period'].blank? ? :month : settings['period'].to_sym))
    calendar.events = TimeEntry.find(:all,
      :conditions => ["user_id = ? AND spent_on BETWEEN ? AND ?", user.id, calendar.startdt, calendar.enddt])
    
    return {:calendar => calendar, :perm_log_time => user.allowed_to?(:log_time, nil, :global => true), :perm_view_time_entries => user.allowed_to?(:view_time_entries, nil, :global => true)}
  end

end