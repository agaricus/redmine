class EpmProjectSidebarSavedQueries < EasyPageModule

  def category_name
    @category_name ||= 'project_sidebar'
  end

  def get_show_data(settings, user, page_context = {})
    if page_zone_module && !page_zone_module.entity_id.blank?
      project = page_context[:project] || Project.find(page_zone_module.entity_id)

      public, personal = Array.new, Array.new
      personal = EasyIssueQuery.private_queries(user) if settings['saved_personal_queries']
      public = EasyIssueQuery.public_queries(user) if settings['saved_public_queries'] && user.easy_user_type == User::EASY_USER_TYPE_INTERNAL

      return {:project => project, :public => public, :personal => personal}
    end
  end

end