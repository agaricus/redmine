class EpmMobileIssuesAssignedToMe < EpmIssuesAssignedToMe
  def show_path
    @show_path ||= "easy_page_modules/mobile_modules/#{module_name}_show"
  end

  def edit_path
    @edit_path ||= "easy_page_modules/mobile_modules/#{module_name}_edit"
  end

  def get_show_data(settings, user, page_context = {})
    query, issues, row_limit = nil, nil, settings['row_limit'].to_i

    settings['visible_issues'] ||= 'assigned'

    query = EasyIssueQuery.new(:name => I18n.t('easy_pages.modules.issues_assigned_to_me'))
    # query.project = page_context[:project] if page_context[:project]

    query.from_params(settings)

    query.add_filter('status_id', 'o', nil)
    if settings['visible_issues'] == 'assigned'
      query.add_filter('assigned_to_id', '=', [user.id.to_s])
    elsif settings['visible_issues'] == 'conserns'
      query.add_filter('participant_id', '=', [user.id.to_s])
    end

    prepared_result_entities = Hash.new

    if page_zone_module
      if query
        issues = query.entities({:include => [:assigned_to, :tracker, :priority, :category, :fixed_version], :limit => (row_limit > 0 ? row_limit : nil)})
      end
    end

    result = {:query => query, :issues => issues, :prepared_result_entities => prepared_result_entities}

    result[:available_ending_buttons] = (settings['mobile_issue_query_end_buttons'] || []).map(&:to_sym)

    return result
  end

  def get_edit_data(settings, user, page_context = {})
    query = EasyIssueQuery.new(:name => 'My')
    query.display_filter_fullscreen_button = false
    if settings['query_type'] == '2'
      settings.delete('query_id')
      query.from_params(settings)
    end

    query.export_formats = {}

    return {:query => query}
  end
end
