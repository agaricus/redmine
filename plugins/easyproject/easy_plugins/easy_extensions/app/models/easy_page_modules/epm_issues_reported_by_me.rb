class EpmIssuesReportedByMe < EasyPageModule

  def category_name
    @category_name ||= 'issues'
  end

  def permissions
    @permissions ||= [:view_issues]
  end

  def get_show_data(settings, user, page_context = {})
    row_limit = settings["row_limit"].blank? ? 10 : settings["row_limit"].to_i
    row_limit = (row_limit <= 0) ? nil : row_limit

    reported_issues = Issue.visible(user).non_templates.open.find(:all,
      :conditions => { :author_id => user.id },
      :include => [ :status, :project, :tracker, :priority ],
      :order => EasySetting.value('issue_default_sorting_string_long'),
      :limit => row_limit)
    
    issues_count = Issue.visible(user).non_templates.open.count(:conditions => { :author_id => user.id })

    return {:reported_issues => reported_issues, :issues_count => issues_count}
  end

end