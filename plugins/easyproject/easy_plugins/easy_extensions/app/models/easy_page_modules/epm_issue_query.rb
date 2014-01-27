class EpmIssueQuery < EasyPageModule

  def category_name
    @category_name ||= 'issues'
  end

  def permissions
    @permissions ||= [:view_issues]
  end

  def get_show_data(settings, user, page_context = {})
    query, issues, row_limit = nil, nil, settings['row_limit'].to_i

    if settings['query_type'] == '2'
      query = EasyIssueQuery.new(:name => settings['query_name'])
      query.project = page_context[:project] if page_context[:project]
      settings.delete('query_id')
      query.from_params(settings)
    elsif !settings['query_id'].blank?
      begin
        query = EasyIssueQuery.find(settings['query_id'])
        query.project = page_context[:project] if page_context[:project]
      rescue ActiveRecord::RecordNotFound
      end
    end

    prepared_result_entities = Hash.new

    if page_zone_module
      if query
        issues = query.entities({:include => [:assigned_to, :tracker, :priority, :category, :fixed_version], :limit => (row_limit > 0 ? row_limit : nil)})
      end
    end

    return {:query => query, :issues => issues, :prepared_result_entities => prepared_result_entities}
  end

  def get_edit_data(settings, user, page_context = {})
    query = EasyIssueQuery.new(:name => settings['query_name'] || '')
    query.display_filter_fullscreen_button = false
    if settings['query_type'] == '2'
      settings.delete('query_id')
      query.from_params(settings)
    end

    query.export_formats = {}

    return {:query => query}
  end

end
