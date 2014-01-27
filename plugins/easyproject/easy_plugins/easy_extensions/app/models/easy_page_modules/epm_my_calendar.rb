class EpmMyCalendar < EasyPageModule

  def category_name
    @category_name ||= 'calendars'
  end

  def permissions
    @permissions ||= [:view_issues]
  end

  def get_show_data(settings, user, page_context = {})
    calendar = Redmine::Helpers::Calendar.new((settings['start_date'] && settings['start_date'].to_date) || Date.today, current_language, :week)
    calendar.events = Issue.visible(user).non_templates.open.includes([:status, :project, :tracker, :priority, :assigned_to]).where(["((#{Issue.table_name}.start_date BETWEEN ? AND ?) OR (#{Issue.table_name}.due_date BETWEEN ? AND ?)) AND #{Issue.table_name}.assigned_to_id = ?", calendar.startdt, calendar.enddt, calendar.startdt, calendar.enddt, user.id])
    calendar.sort_block {|is1,is2| is2.easy_start_date_time.to_i <=> is1.easy_start_date_time.to_i}

    return {:calendar => calendar}
  end

  def get_edit_data(settings, user, page_context = {})
    return get_show_data(settings, user, page_context)
  end

end