require 'icalendar'

module EasyIcalHelper

  def issues_to_ical(issues, options={})
    icalendar = Icalendar::Calendar.new
    icalendar.custom_property('METHOD', 'PUBLISH')
    icalendar.custom_property('X-MS-OLK-FORCEINSPECTOROPEN', 'TRUE')
    issues.each{|issue| icalendar = issue_to_ical_obj(icalendar, issue)}
    icalendar.to_ical
  end

  def issue_to_ical(issue, options={})
    icalendar = Icalendar::Calendar.new
    if options[:method] == 'request'
      icalendar.custom_property('METHOD', 'REQUEST')
    else
      icalendar.custom_property('METHOD', 'PUBLISH')
    end
    icalendar.custom_property('X-MS-OLK-FORCEINSPECTOROPEN', 'FALSE')
    icalendar = issue_to_ical_obj(icalendar, issue)
    icalendar.to_ical
  end

  def issue_to_ical_obj(icalendar, issue)
    cv_start, cv_end, cv_location = get_issue_ical_start_date(issue), get_issue_ical_end_date(issue), get_issue_ical_location(issue)
    issue_url = url_for(:controller => 'issues', :action => 'show', :id => issue, :only_path => false)

    icalendar.event do
      dtstart(cv_start.is_a?(Date) ? cv_start : cv_start.strftime("%Y%m%dT%H%M%S")) if !cv_start.blank?
      dtend(cv_end.is_a?(Date) ? cv_end : cv_end.strftime("%Y%m%dT%H%M%S")) if !cv_end.blank?
      summary(issue.subject)
      description(Sanitize.clean(issue.description.to_s, :output => :html).strip)
      created(issue.created_on.to_datetime.strftime("%Y%m%dT%H%M%S"))
      last_modified(issue.updated_on.to_datetime.strftime("%Y%m%dT%H%M%S"))
      uid(issue.id.to_s + '@' + Setting.host_name)
      url(issue_url)
      sequence(0)
      transparency('OPAQUE')
      klass('PUBLIC')
      location(cv_location) unless cv_location.blank?
      priority('5')
      status('CONFIRMED')

      custom_property('X-MICROSOFT-CDO-BUSYSTATUS', 'BUSY')
      custom_property('X-MICROSOFT-CDO-IMPORTANCE', '1')
      custom_property('X-MICROSOFT-DISALLOW-COUNTER', 'FALSE')
      custom_property('X-MS-OLK-AUTOFILLLOCATION', 'FALSE')
      custom_property('X-MS-OLK-AUTOSTARTCHECK', 'FALSE')
      custom_property('X-MS-OLK-CONFTYPE', '0')

      organizer("mailto:#{issue.author.mail}")

      if issue.assigned_to
        add_attendee("mailto:#{issue.assigned_to.mail}")
      end

      unless issue.watcher_users.blank?
        issue.watcher_users.each do |w|
          next if w.mail.blank?
          add_attendee("mailto:#{w.mail}")
        end
      end
    end
    icalendar
  end

  def get_issue_ical_start_date(issue)
    datetimes = issue.available_custom_fields && issue.available_custom_fields.select{|cf| cf.field_format == 'datetime'}
    cf_start = datetimes && datetimes.first
    cv_start = issue.custom_value_for(cf_start) if cf_start

    return_start_date = cv_start.cast_value if cv_start
    return_start_date ||= User.current.user_time_in_zone(issue.easy_start_date_time) if issue.respond_to?(:easy_start_date_time) && !issue.easy_start_date_time.nil?
    return_start_date ||= issue.start_date
    return_start_date ||= issue.due_date
    return return_start_date
  end

  def get_issue_ical_end_date(issue)
    datetimes = issue.available_custom_fields && issue.available_custom_fields.select{|cf| cf.field_format == 'datetime'}
    cf_end = datetimes && datetimes.second
    cv_end = issue.custom_value_for(cf_end) if cf_end

    return_end_date = cv_end.cast_value if cv_end
    return_end_date ||= User.current.user_time_in_zone(issue.easy_due_date_time) if issue.respond_to?(:easy_due_date_time) && !issue.easy_due_date_time.nil?
    return_end_date ||= issue.due_date
    return_end_date ||= issue.start_date
    if return_end_date && return_end_date.is_a?(Date)
      return_end_date += 1.day
    end
    return return_end_date
  end

  def get_issue_ical_location(issue)
    return nil #due to weird method
    cf_location = issue.custom_value_for(4)
    if cf_location
      cf_location.cast_value
    else
      nil
    end
  end

end
