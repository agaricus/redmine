class EpmAttendance < EasyPageModule

  include EasyUtils::DateUtils

  def category_name
    @category_name ||= 'others'
  end

  def permissions
    @permissions ||= [:view_easy_attendances]
  end

  def default_settings
    @default_settings ||= HashWithIndifferentAccess.new('query_type' => '2', 'output' => 'calendar', 'period' => 'week',
      'column_names' => EasySetting.value('easy_attendance_query_list_default_columns'),
      'fields' => ['arrival', 'user_id'],
      'operators' => HashWithIndifferentAccess.new('arrival' => 'date_period_1', 'user_id' => '='),
      'values' => HashWithIndifferentAccess.new('arrival' => HashWithIndifferentAccess.new('period' => 'current_week'), 'user_id' => ['me'])
    )
  end

  def runtime_permissions(user)
    EasyAttendance.enabled?
  end

  def get_show_data(settings, user, page_context = {})
    query, easy_user_working_time_calendar = nil, nil
    period = settings['period'].blank? ? :week : settings['period'].to_sym

    prepared_result_entities = Hash.new

    unless user.in_mobile_view?
      if settings['query_type'] == '2'
        query = EasyAttendanceQuery.new(:name => settings['query_name'])
        query.from_params(settings)
      elsif !settings['query_id'].blank?
        begin
          query = EasyAttendanceQuery.find(settings['query_id'])
        rescue ActiveRecord::RecordNotFound
        end
      end

      if query && settings['output'] == 'calendar'
        start_date = begin; settings['start_date'].to_date; rescue; end

        arrival_filter = query.filters['arrival'] || query.filters['departure']
        if start_date.nil? && arrival_filter && arrival_filter[:operator].to_s =~ /date_period_([12])/
          filter_period = arrival_filter[:values][:period]
          unless $1 == '1' && filter_period.to_sym == :all
            period_dates = self.get_date_range($1, filter_period, arrival_filter[:values][:from], arrival_filter[:values][:to])
            start_date ||= (period_dates[:from].nil? ? nil : period_dates[:from].end_of_day.to_date)
          end
        end

        calendar = EasyAttendances::Calendar.new(start_date || User.current.today, current_language, period)
        query.filters.delete('departure')
        query.filters['arrival'] = HashWithIndifferentAccess.new(:operator => 'date_period_2', :values => HashWithIndifferentAccess.new('from' => calendar.startdt, 'to' => calendar.enddt, 'period' => ''))

        resulted_entities = query.entities(:order => :arrival)

        easy_user_working_time_calendar = get_easy_user_working_time_calendar(query)

        calendar.events = resulted_entities

      elsif query
        prepared_result_entities = query.prepare_result
      end
    end

    easy_attendance = EasyAttendance.new_or_last_attendance(user)

    first_non_closed_attendance = EasyAttendance.where(:departure => nil).where(["arrival < ?", Date.today]).where(:user_id => user.id).first

    return {:query => query, :prepared_result_entities => prepared_result_entities, :calendar => calendar, :easy_attendance => easy_attendance, :easy_user_working_time_calendar => easy_user_working_time_calendar, :first_non_closed_attendance => first_non_closed_attendance, :period => period}
  end

  def get_edit_data(settings, user, page_context = {})
    query = EasyAttendanceQuery.new(:name => settings['query_name'] || '')
    query.from_params(settings) if settings['query_type'] == '2'
    query.display_filter_fullscreen_button = false

    return {:query => query}
  end

  private

  def get_easy_user_working_time_calendar(query)
    return nil unless query.is_a?(EasyQuery)

    if user_filter = query.filters['user_id']

      user_ids = Array(user_filter[:values])

      if user_ids.size == 1
        user_id = user_ids.first
      end

      user_id = User.current.id if user_ids.include?('me')

      return EasyUserWorkingTimeCalendar.where(:user_id => user_id).first if user_id
    end

    return nil
  end

end
