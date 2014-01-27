class EpmProjectTree < EasyPageModule

  def category_name
    @category_name ||= 'projects'
  end

  def get_show_data(settings, user, page_context = {})
    if page_zone_module && !page_zone_module.entity_id.blank?
      project = page_context[:project] || Project.find(page_zone_module.entity_id)

      if project.easy_is_easy_template?
        projects = project.descendants.templates.active.reorder(:lft).all
      else
        projects = project.descendants.non_templates.visible.reorder(:lft).all
      end

      return {:projects => projects}
    end
  end

end