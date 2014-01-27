class EpmProjectNews < EasyPageModule

  def permissions
    @permissions ||= [:view_news]
  end

  def category_name
    @category_name ||= 'others'
  end

  def get_show_data(settings, user, page_context = {})
    if page_zone_module && !page_zone_module.entity_id.blank?
      project = page_context[:project] || Project.find(page_zone_module.entity_id)
      news = project.news.includes(:project, :author).order("#{News.table_name}.spinned DESC, #{News.table_name}.created_on DESC").limit(5).all

      return {:project => project, :news => news}
    end
  end

end