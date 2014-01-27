class EpmProjectsQuery < EasyPageModule

  def category_name
    @category_name ||= 'projects'
  end

  def permissions
    @permissions ||= [:view_project]
  end

  def get_show_data(settings, user, page_context = {})
    query, projects, row_limit = nil, nil, settings['row_limit'].to_i

    if settings['query_type'] == '2'
      query = EasyProjectQuery.new(:name => settings['query_name'])
      query.from_params(settings)
    elsif !settings['query_id'].blank?
      begin
        query = EasyProjectQuery.find(settings['query_id'])
      rescue ActiveRecord::RecordNotFound
      end
    end

    if query
      additional_statement = "#{Project.table_name}.easy_is_easy_template=#{query.connection.quoted_false}"
      additional_statement << (' AND ' + Project.visible_condition(User.current))

      if query.additional_statement.blank?
        query.additional_statement = additional_statement
      else
        query.additional_statement << ' AND ' + additional_statement
      end
    end

    prepared_result_entities = Hash.new

    if query && settings['output'] == 'calendar'
      projects = query.entities({:limit => (row_limit > 0 ? row_limit : nil)})
    elsif query
      prepared_result_entities = query.prepare_result({:limit => (row_limit > 0 ? row_limit : nil), :order => "#{Project.table_name}.lft"})
      if !query.grouped?
        ancestors = []
        ancestor_conditions = prepared_result_entities[nil][:entities].collect{|project| "(#{Project.left_column_name} < #{project.left} AND #{Project.right_column_name} > #{project.right})"}
        if ancestor_conditions.any?
          ancestor_conditions = "(#{ancestor_conditions.join(' OR ')})  AND (#{Project.table_name}.id NOT IN (#{prepared_result_entities[nil][:entities].collect(&:id).join(',')}))"
          ancestors = Project.find(:all, :conditions => ancestor_conditions)
        end

        ancestors.each do |p|
          p.nofilter = 'nofilter'
        end

        prepared_result_entities[nil][:entities] << ancestors
        prepared_result_entities[nil][:entities] = prepared_result_entities[nil][:entities].flatten.uniq.sort_by(&:lft)
      end
    end

    return {:query => query, :projects => projects, :prepared_result_entities => prepared_result_entities}
  end

  def get_edit_data(settings, user, page_context = {})
    query = EasyProjectQuery.new(:name => (settings['query_name'] || '_'))
    query.display_filter_fullscreen_button = false
    query.from_params(settings) if settings['query_type'] == '2'

    return {:query => query}
  end

end
