class EpmMyProjectsSimple < EasyPageModule

  def category_name
    @category_name ||= 'projects'
  end

  def get_show_data(settings, user, page_context = {})
    projects = Project.visible(user).non_templates.all

    return {:projects => projects}
  end

end
