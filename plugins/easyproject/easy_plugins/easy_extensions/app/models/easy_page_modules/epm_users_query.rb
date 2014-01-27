class EpmUsersQuery < EasyPageModule

  def category_name
    @category_name ||= 'users'
  end

  def permissions
    @permissions ||= [:view_project_overview_users_query]
  end

  def get_show_data(settings, user, page_context = {})
    query, users, row_limit = nil, nil, settings['row_limit'].to_i

    if settings['query_type'] == '2'
      query = EasyMemberQuery.new(:name => settings['query_name'])
      query.from_params(settings)
    elsif !settings['query_id'].blank?
      begin
        query = EasyMemberQuery.find(settings['query_id'])
      rescue ActiveRecord::RecordNotFound
      end
    end

    project = page_context[:project]

    if query
      query.add_additional_statement("#{User.table_name}.status = 1")
      query.add_additional_statement("#{Member.table_name}.project_id = #{project.id}") if project
    end

    prepared_result_entities = Hash.new
    if query
      prepared_result_entities = query.prepare_result({:limit => (row_limit > 0 ? row_limit : nil)})
    end

    return {:query => query, :users => users, :prepared_result_entities => prepared_result_entities}
  end
  
  def get_edit_data(settings, user, page_context = {})
    query = EasyMemberQuery.new(:name => (settings['query_name'] || '_'))
    query.display_filter_fullscreen_button = false
    query.from_params(settings) if settings['query_type'] == '2'
    
    return {:query => query}
  end

end