class EpmIssuesAssignedToMe < EasyPageModule

  def category_name
    @category_name ||= 'issues'
  end

  def permissions
    @permissions ||= [:view_issues]
  end

  def get_show_data(settings, user, page_context = {})
    row_limit = settings["row_limit"].blank? ? 10 : settings["row_limit"].to_i
    row_limit = (row_limit <= 0) ? nil : row_limit

    settings['visible_issues'] ||= 'assigned'

    query = EasyIssueQuery.new(:name => 'My', :column_names => [:project, :subject, :done_ratio, :due_date] )
    query.add_filter('status_id', 'o', nil)
    query.add_filter('is_planned', '=', ['0'])
    if settings['visible_issues'] == 'assigned'
      query.add_filter('assigned_to_id', '=', [user.id.to_s])
    elsif settings['visible_issues'] == 'conserns'
      query.column_names += [:assigned_to, :author]
      query.add_filter('participant_id', '=', [user.id.to_s])
    end

    issues_count = query.entity_count
    assigned_issues = query.prepare_result(:includes => [:status, :project, :tracker, :priority ], :limit => row_limit, :order => EasySetting.value('issue_default_sorting_string_long'))
    #.order(EasySetting.value('issue_default_sorting_string_long')).limit(row_limit).all if scope

    issues_count ||= 0
    assigned_issues ||= {}

    return {:query => query, :assigned_issues => assigned_issues, :issues_count => issues_count, :only_assigned => (settings['visible_issues'] == 'assigned') }
  end

end
