class EpmProjectIssues < EasyPageModule

  def category_name
    @category_name ||= 'issues'
  end

  def get_show_data(settings, user, page_context = {})
    if page_zone_module && !page_zone_module.entity_id.blank?
      project = page_context[:project] || Project.find(page_zone_module.entity_id)
      query = EasyIssueQuery.new(:name => '_', :project => project)

      additional_statement = "(#{project.project_condition(Setting.display_subprojects_issues?)}) AND #{IssueStatus.table_name}.is_closed=#{connection.quoted_false}"
      if query.additional_statement.blank?
        query.additional_statement = additional_statement
      else
        query.additional_statement << ' AND ' + additional_statement
      end

      prepared_result_entities = query.entities({:includes => [:status], :limit => 10, :order => EasySetting.value('issue_default_sorting_string_long', project)})

      return {:query => query, :prepared_result_entities => prepared_result_entities, :sort => EasySetting.value('issue_default_sorting_string_short', project)}
    end

  end

end
