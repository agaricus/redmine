class EpmProjectHistory < EasyPageModule

  def category_name
    @category_name ||= 'projects'
  end

  def get_show_data(settings, user, page_context = {})
    if page_zone_module && !page_zone_module.entity_id.blank?
      project = page_context[:project] || Project.find(page_zone_module.entity_id)

      journals = project.journals.includes(:user, :details).reorder("#{Journal.table_name}.id ASC").all
      journals.each_with_index {|j,i| j.indice = i+1}
      journals.reject!(&:private_notes?) unless User.current.allowed_to?(:view_private_notes, project)
      journals.reverse! if User.current.wants_comments_in_reverse_order?

      return {:project => project, :journals => journals}
    end
  end

end