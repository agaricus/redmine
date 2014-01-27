class EpmUserAllocation < EasyPageModule
  
  include EasyUtils::DateUtils

  def category_name
    @category_name ||= 'users'
  end
  
  def permissions
    @permissions ||= [:view_issues]
  end

  def default_settings
    {'query_type' => '2'}
  end
  
  def get_show_data(settings, user, page_context={})

    if settings['query_type'] == '2'
      query = EasyUserAllocationQuery.new(:name => settings['query_name'])
      query.from_params(settings)
    elsif !settings['query_id'].blank?
      begin
        query = EasyUserAllocationQuery.find(settings['query_id'])
      rescue ActiveRecord::RecordNotFound
      end
    end

    if range = (query && query.filters['range'])
      period = get_date_range(range[:operator].split('_').last, range[:values][:period],range[:values][:from], range[:values][:to])
      period[:to] ||= Date.today
      period[:from] ||= Date.today
      period[:months] = (period[:to].year*12+period[:to].month)-(period[:from].year*12+period[:from].month) + 1
      period[:period_type] = range[:operator].split('_').last
      period[:period] = range[:values][:period]
    else
      period = Hash.new
    end

    return {:query => query, :period => period}
  end

  def get_edit_data(settings, user, page_context = {})
    query = EasyUserAllocationQuery.new(:name => settings['query_name'] || '')
    query.from_params(settings) if settings['query_type'] == '2'
    query.add_filter('user_login', '=', [User.current.login]) if settings == default_settings
    query.display_filter_sort_on_index, query.display_filter_columns_on_index, query.display_filter_group_by_on_index = false, false, false
    query.display_filter_fullscreen_button = false

    return {:query => query}
  end
  
end