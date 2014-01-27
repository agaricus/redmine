class EpmProjectSidebarFamilyInfo < EasyPageModule

  def category_name
    @category_name ||= 'project_sidebar'
  end

  def get_show_data(settings, user, page_context = {})
    if page_zone_module && !page_zone_module.entity_id.blank?
      project = page_context[:project] || Project.find(page_zone_module.entity_id)

      return {:project => project}
    end
  end


end