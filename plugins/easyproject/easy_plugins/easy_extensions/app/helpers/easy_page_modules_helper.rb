module EasyPageModulesHelper

  def epm_easy_queries(page_module, query_class)
    scope = query_class.scoped(:include => :project).order("#{query_class.table_name}.name ASC")

    if page_module.is_a?(EasyPageZoneModule)
      if !page_module.entity_id.blank?
        scope = scope.where(["#{query_class.table_name}.visibility = ?", EasyQuery::VISIBILITY_PUBLIC])
      elsif !page_module.user_id.blank?
        scope = scope.where(["#{query_class.table_name}.visibility = ? OR #{query_class.table_name}.user_id = ?", EasyQuery::VISIBILITY_PUBLIC, page_module.user_id])
      else
        raise ArgumentError, 'The page_module is not valid EasyPageZoneModule.'
      end
    elsif page_module.is_a?(EasyPageTemplateModule)
      scope = scope.where(["#{query_class.table_name}.visibility = ?", EasyQuery::VISIBILITY_PUBLIC])
    else
      raise ArgumentError, 'The page_module has to be EasyPageZoneModule or EasyPageTemplateModule.'
    end

    scope = scope.where(["#{Project.table_name}.status = ? OR #{query_class.table_name}.project_id IS NULL", Project::STATUS_ACTIVE])
    scope.all
  end

  # *modul_uniq_id* => Uniq page module id
  # *url* => url_for action where is preview
  # *update* => HTML element which is updated after complete ajax
  # *label* => label of button
  def adhoc_preview_button(modul_uniq_id, options)
    url = options.delete(:url) || url_for({:controller => 'easy_queries', :action => 'preview'})
    fce = "selectAllOptions('#{modul_uniq_id}selected_columns');"
    fce << "$.post('#{url}', $(this).parents('form').serialize(), function(data) {$('##{options.delete(:update)}').html(data)})"
    return link_to_function( options.delete(:label) || l(:label_preview), fce,{ :class => 'icon icon-checked apply-link'}.merge!(options))
  end

end
