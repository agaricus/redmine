require 'easy_extensions/timelog/timelog_calendar'

class EpmResourceAvailability < EasyPageModule

  def category_name
    @category_name ||= 'others'
  end

  def get_show_data(settings, user, page_context = {})
    if self.page_zone_module
      start_date = settings['start_date'].blank? ? Date.today : settings['start_date'].to_date
      calendar = EasyExtensions::Timelog::Calendar.new(start_date, (user || User.current).language, :week)
      timeline = EasyResourceAvailability.timeline(self.page_zone_module.uuid, calendar.startdt, calendar.enddt)
    end

    return {:calendar => calendar, :timeline => timeline}
  end

end
