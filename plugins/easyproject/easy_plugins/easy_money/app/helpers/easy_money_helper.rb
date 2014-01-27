module EasyMoneyHelper

  def get_easy_money_projects
    projects = Project.find(:all, :conditions => Project.allowed_to_condition(User.current, :view_easy_money), :include => :easy_money_time_entry_expenses)
    ancestor_conditions = projects.collect{|project| "(#{Project.left_column_name} < #{project.left} AND #{Project.right_column_name} > #{project.right})"}
    parents = ancestor_conditions.any? ? Project.find(:all, :conditions => ancestor_conditions.join(' OR '), :include => :easy_money_time_entry_expenses) : []
    (projects | parents).sort_by(&:lft)
  end

  def time_entry_expenses_columns_per_rate_type(project, time_entry)
    html = ''

    if project.easy_money_settings.show_rate?('all')
      EasyMoneyRateType.active.each_with_index do |rate_type, i|
        html << '<td class="column">'
        html << time_entry_expense_per_rate_type(project, time_entry, rate_type, :format_price => true)
        html << '</td>'
      end
    else
      html << '<td class="column">'
      html << time_entry_expense_per_rate_type(project, time_entry, EasyMoneyRateType.active.find(:first), :format_price => true)
      html << '</td>'
      html << '<td class="column">N/A</td>'
    end
    html.html_safe
  end

  def price_validation
    if params[:easy_money][:price1] && params[:easy_money][:price2] && ((params[:easy_money][:price1].to_f != 0.0 && params[:easy_money][:price2].to_f == 0.0) || (params[:easy_money][:price1].to_f == 0.0 && params[:easy_money][:price2].to_f != 0.0))
      if params[:use_vat] && params[:use_vat].to_i == 1
        if params[:easy_money][:price1].to_f == 0.0
          params[:easy_money][:price1] = EasyMoneyEntity.compute_price1(@project, params[:easy_money][:price2].to_f)
        elsif params[:easy_money][:price2].to_f == 0.0
          params[:easy_money][:price2] = EasyMoneyEntity.compute_price2(@project, params[:easy_money][:price1].to_f)
        end
      else
        if params[:easy_money][:price1].to_f == 0.0
          params[:easy_money][:price1] = params[:easy_money][:price2]
        elsif params[:easy_money][:price2].to_f == 0.0
          params[:easy_money][:price2] = params[:easy_money][:price1]
        end
      end
    end
  end

  def add_price2
    unless params[:easy_money][:price2]
      params[:easy_money][:vat] = @project.easy_money_settings.vat.to_f
      params[:easy_money][:price2] = EasyMoneyEntity.compute_price2(@project, params[:easy_money][:price1])
    end
  end

  def find_easy_money_project
    entity_id = (params[:easy_money] && params[:easy_money][:entity_id]) || params[:entity_id]
    entity_type = (params[:easy_money] && params[:easy_money][:entity_type]) || params[:entity_type]

    if @easy_money_object
      @entity = @easy_money_object.entity
      @entity_type = @easy_money_object.entity_type
      @entity_id = @easy_money_object.entity_id
      @project = @entity.project
    elsif entity_id && entity_type && EasyMoneyEntity.allowed_entities.include?(entity_type)
      @entity = entity_type.constantize.find(entity_id)
      @entity_type = entity_type
      @entity_id = entity_id
      @project = @entity.project
    elsif !params[:project_id].blank?
      @project = Project.find(params[:project_id])
      @entity = @project
      @entity_type = 'Project'
      @entity_id = @project.id
    end
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def easy_money_sub_heading(entity = nil)
    entity ||= @entity
    return '' if entity.nil?

    case entity.class.name
    when 'Project'
      (l(:label_project) + ' - ' + h(entity)).html_safe
    when 'Issue'
      (l(:label_issue) + ' - ' + h(entity)).html_safe
    when 'Version'
      (l(:label_version) + ' - ' + h(entity)).html_safe
    end
  end

  def link_to_easy_money_overview(entity = nil)
    entity ||= @entity
    return '' if entity.nil?
    entity_type = entity.class.name
    label = l(:"label_easy_money_sidebar.#{entity_type.underscore}")
    case entity_type
    when 'Project'
      link_to(label, {:controller => 'easy_money', :action => 'project_index', :project_id => entity}, :title => label, :class=> 'button-2')
    when 'Issue'
      link_to(label, {:controller => 'issues', :action => 'show', :id => entity}, :title => label, :class=> 'button-2')
    when 'Version'
      link_to(label, {:controller => 'versions', :action => 'show', :id => entity, :anchor => 'easy_money_version'}, :title => label, :class=> 'button-2')
    end
  end

  def easy_money_expected_expense_query_additional_beginning_buttons(entity, options = {})
    s = ''
    if entity.easy_external_id
      s << content_tag(:span, '', :title => l(:title_model_has_easy_external_id), :class => 'icon icon-relation')
    end
    s.html_safe
  end

  def easy_money_expected_expense_query_additional_ending_buttons(entity, options = {})
    s = ''
    if User.current.allowed_to?(:easy_money_manage_expected_expense, entity.project)
      s << link_to(l(:button_edit), {:controller => 'easy_money_expected_expenses', :action => 'edit', :id => entity, :back_url => url_for(params)}, :class => 'icon icon-edit')
      s << link_to(l(:button_delete), {:controller => 'easy_money_expected_expenses', :action => 'destroy', :id => entity, :back_url => url_for(params)}, :method => :delete, :data => {:confirm => l(:text_are_you_sure)}, :class => 'icon icon-del')
    end
    s.html_safe
  end

  def easy_money_expected_revenue_query_additional_beginning_buttons(entity, options = {})
    s = ''
    if entity.easy_external_id
      s << content_tag(:span, '', :title => l(:title_model_has_easy_external_id), :class => 'icon icon-relation')
    end
    s.html_safe
  end

  def easy_money_expected_revenue_query_additional_ending_buttons(entity, options = {})
    s = ''
    if User.current.allowed_to?(:easy_money_manage_expected_revenue, entity.project)
      s << link_to(l(:button_edit), {:controller => 'easy_money_expected_revenues', :action => 'edit', :id => entity, :back_url => url_for(params)}, :class => 'icon icon-edit')
      s << link_to(l(:button_delete), {:controller => 'easy_money_expected_revenues', :action => 'destroy', :id => entity, :back_url => url_for(params)}, :method => :delete, :data => {:confirm => l(:text_are_you_sure)}, :class => 'icon icon-del')
    end
    s.html_safe
  end

  def easy_money_other_expense_query_additional_beginning_buttons(entity, options = {})
    s = ''
    if entity.easy_external_id
      s << content_tag(:span, '', :title => l(:title_model_has_easy_external_id), :class => 'icon icon-relation')
    end
    s.html_safe
  end

  def easy_money_other_expense_query_additional_ending_buttons(entity, options = {})
    s = ''
    if User.current.allowed_to?(:easy_money_manage_other_revenue, entity.project)
      s << link_to(l(:button_edit), {:controller => 'easy_money_other_expenses', :action => 'edit', :id => entity, :back_url => url_for(params)}, :class => 'icon icon-edit')
      s << link_to(l(:button_delete), {:controller => 'easy_money_other_expenses', :action => 'destroy', :id => entity, :back_url => url_for(params)}, :method => :delete, :data => {:confirm => l(:text_are_you_sure)}, :class => 'icon icon-del')
    end
    s.html_safe
  end

  def easy_money_other_revenue_query_additional_beginning_buttons(entity, options = {})
    s = ''
    if entity.easy_external_id
      s << content_tag(:span, '', :title => l(:title_model_has_easy_external_id), :class => 'icon icon-relation')
    end
    s.html_safe
  end

  def easy_money_other_revenue_query_additional_ending_buttons(entity, options = {})
    s = ''
    if User.current.allowed_to?(:easy_money_manage_other_revenue, entity.project)
      s << link_to(l(:button_edit), {:controller => 'easy_money_other_revenues', :action => 'edit', :id => entity, :back_url => url_for(params)}, :class => 'icon icon-edit')
      s << link_to(l(:button_delete), {:controller => 'easy_money_other_revenues', :action => 'destroy', :id => entity, :back_url => url_for(params)}, :method => :delete, :data => {:confirm => l(:text_are_you_sure)}, :class => 'icon icon-del')
    end
    s.html_safe
  end

  def easy_money_subprojects_table(project, subprojects)
    html = ''
    show_time_tracking = project.self_and_descendants.active.has_module(:time_tracking).size > 0
    html << easy_money_subproject_table(project, show_time_tracking, :only_self => true)
    Array(subprojects).each do |subproject|
      html << easy_money_subproject_table(subproject, show_time_tracking)
    end
    html.html_safe
  end

  def easy_money_subproject_table(subproject, show_time_tracking, options={})
    html = ''
    subproject_price_type = subproject.easy_money_settings.expected_count_price.to_sym
    subproject_rate_type = EasyMoneyRateType.active.find(:first, :conditions => {:name => subproject.easy_money_settings.expected_rate_type}) || EasyMoneyRateType.active.find(:first, :order => :position)
    subproject_show_expected = subproject.easy_money_settings.show_expected?
    html << '<tr>'
    html << '<td class="project-name">'
    html << link_to(subproject.name, { :controller => 'easy_money', :action => 'project_index', :project_id => subproject.id }, { :title => l(:title_easy_money_link_to_subproject, :subproject => subproject.name) })
    html << '</td>'
    html << '<td class="easy-money-sum-revenues">'
    if subproject_show_expected
      if User.current.allowed_to?(:easy_money_show_expected_revenue, subproject) || User.current.allowed_to?(:easy_money_manage_expected_revenue, subproject)
        value = subproject.easy_money.sum_expected_revenues(subproject_price_type, options)
        html << content_tag(:span, format_easy_money_price(value, subproject), :title => l(:title_easy_money_sum_expected_revenues, :project => subproject.name, :value => format_easy_money_price(value, subproject, :no_html => true)))
      end
      html << ' / '
      if User.current.allowed_to?(:easy_money_show_other_revenue, subproject) || User.current.allowed_to?(:easy_money_manage_other_revenue, subproject)
        value = subproject.easy_money.sum_other_revenues(subproject_price_type, options)
        html << content_tag(:span, format_easy_money_price(value, subproject), :title => l(:title_easy_money_sum_other_revenues, :project => subproject.name, :value => format_easy_money_price(value, subproject, :no_html => true)))
      end
    else
      if User.current.allowed_to?(:easy_money_show_other_revenue, subproject) || User.current.allowed_to?(:easy_money_manage_other_revenue, subproject)
        value = subproject.easy_money.sum_other_revenues(subproject_price_type, options)
        html << content_tag(:span, format_easy_money_price(value, subproject), :title => l(:title_easy_money_sum_other_revenues, :project => subproject.name, :value => format_easy_money_price(value, subproject, :no_html => true)))
      end
    end
    html << '</td>'
    html << '<td class="easy-money-sum-expenses">'
    if subproject_show_expected
      if User.current.allowed_to?(:easy_money_show_expected_expense, subproject) || User.current.allowed_to?(:easy_money_manage_expected_expense, subproject)
        value = subproject.easy_money.sum_expected_expenses(subproject_price_type, options)
        html << content_tag(:span, format_easy_money_price(value, subproject), :title => l(:title_easy_money_sum_expected_expenses, :project => subproject.name, :value => format_easy_money_price(value, subproject, :no_html => true)))
      end
      html << ' / '
      if User.current.allowed_to?(:easy_money_show_other_expense, subproject) || User.current.allowed_to?(:easy_money_manage_other_expense, subproject)
        value = subproject.easy_money.sum_other_expenses(subproject_price_type, options)
        html << content_tag(:span, format_easy_money_price(value, subproject), :title => l(:title_easy_money_sum_other_expenses, :project => subproject.name, :value => format_easy_money_price(value, subproject, :no_html => true)))
      end
    else
      if User.current.allowed_to?(:easy_money_show_other_expense, subproject) || User.current.allowed_to?(:easy_money_manage_other_expense, subproject)
        value = subproject.easy_money.sum_other_expenses(subproject_price_type, options)
        html << content_tag(:span, format_easy_money_price(value, subproject), :title => l(:title_easy_money_sum_other_expenses, :project => subproject.name, :value => format_easy_money_price(value, subproject, :no_html => true)))
      end
    end
    html << '</td>'
    if show_time_tracking
      html << '<td class="easy-money-sum-payroll-expenses">'
      if subproject_show_expected
        if subproject.self_and_descendants.active.has_module(:time_tracking).size > 0
          if User.current.allowed_to?(:easy_money_show_expected_payroll_expense, subproject) || User.current.allowed_to?(:easy_money_manage_expected_payroll_expense, subproject)
            value = subproject.easy_money.sum_expected_payroll_expenses(options)
            html << content_tag(:span, format_easy_money_price(value, subproject), :title => l(:title_easy_money_sum_expected_payroll_expenses, :project => subproject.name, :value => format_easy_money_price(value, subproject, :no_html => true)))
          end
          html << ' / '
          if User.current.allowed_to?(:easy_money_show_time_entry_expenses, subproject)
            value = subproject.easy_money.sum_time_entry_expenses(subproject_rate_type, options)
            html << content_tag(:span, format_easy_money_price(value, subproject), :title => l(:title_easy_money_sum_time_entry_expenses, :project => subproject.name, :value => format_easy_money_price(value, subproject, :no_html => true)))
          end
        else
          html << l(:label_not_available) + ' / ' + l(:label_not_available)
        end
      else
        if subproject.self_and_descendants.active.has_module(:time_tracking).size > 0
          if User.current.allowed_to?(:easy_money_show_time_entry_expenses, subproject)
            value = subproject.easy_money.sum_time_entry_expenses(subproject_rate_type, options)
            html << content_tag(:span, format_easy_money_price(value, subproject), :title => l(:title_easy_money_sum_time_entry_expenses, :project => subproject.name, :value => format_easy_money_price(value, subproject, :no_html => true)))
          end
        else
          html << l(:label_not_available)
        end
      end
      html << '</td>'
    end
    html << '<td class="easy-money-profit">'
    if subproject_show_expected
      if User.current.allowed_to?(:easy_money_show_expected_profit, subproject)
        value = subproject.easy_money.expected_profit(subproject_price_type, options)
        html << content_tag(:span, format_easy_money_price(value, subproject), :title => l(:title_easy_money_expected_profit, :project => subproject.name, :value => format_easy_money_price(value, subproject, :no_html => true)))
      end
      html << ' / '
      if User.current.allowed_to?(:easy_money_show_other_profit, subproject)
        value = subproject.easy_money.other_profit(subproject_price_type, subproject_rate_type, options)
        html << content_tag(:span, format_easy_money_price(value, subproject), :title => l(:title_easy_money_other_profit, :project => subproject.name, :value => format_easy_money_price(value, subproject, :no_html => true)))
      end
    else
      if User.current.allowed_to?(:easy_money_show_other_profit, subproject)
        value = subproject.easy_money.other_profit(subproject_price_type, subproject_rate_type, options)
        html << content_tag(:span, format_easy_money_price(value, subproject), :title => l(:title_easy_money_other_profit, :project => subproject.name, :value => format_easy_money_price(value, subproject, :no_html => true)))
      end
    end
    html << '</td>'
    html << '<td>'
    if subproject.easy_money_settings.revenues_type == 'list'
      if User.current.allowed_to?(:easy_money_manage_other_revenue, subproject)
        html << link_to('', { :controller => 'easy_money_other_revenues', :action => 'new', :project_id => subproject.id, :'easy_money[entity_type]' => 'Project', :'easy_money[entity_id]' => subproject.id}, { :title => l(:title_easy_money_project_new_revenue), :alt => l(:button_easy_money_project_new_revenue) , :class => 'icon icon-add'})
      elsif User.current.allowed_to?(:easy_money_manage_expected_revenue, subproject)
        html << link_to('', { :controller => 'easy_money_expected_revenues', :action => 'new', :project_id => subproject.id, :'easy_money[entity_type]' => 'Project', :'easy_money[entity_id]' => subproject.id }, { :title => l(:title_easy_money_project_new_revenue), :alt => l(:button_easy_money_project_new_revenue) , :class => 'icon icon-add'})
      end
    end
    html << '</td>'
    html << '<td>'
    if subproject.easy_money_settings.expenses_type == 'list'
      if User.current.allowed_to?(:easy_money_manage_other_expense, subproject)
        html << link_to('', { :controller => 'easy_money_other_expenses', :action => 'new', :project_id => subproject.id, :'easy_money[entity_type]' => 'Project', :'easy_money[entity_id]' => subproject.id }, { :title => l(:title_easy_money_project_new_expense), :alt => l(:button_easy_money_project_new_expense), :class => 'icon icon-remove' })
      elsif User.current.allowed_to?(:easy_money_manage_expected_expense, subproject)
        html << link_to('', { :controller => 'easy_money_expected_expenses', :action => 'new', :project_id => subproject.id, :'easy_money[entity_type]' => 'Project', :'easy_money[entity_id]' => subproject.id}, { :title => l(:title_easy_money_project_new_expense), :alt => l(:button_easy_money_project_new_expense), :class => 'icon icon-remove' })
      end
    end
    html << '</td>'
    html << '</tr>'
    html.html_safe
  end

  def options_for_period_select(value)
    options_for_select([
        [l("easy_money_period.daily"), 'daily'],
        [l("easy_money_period.monthly"), 'monthly'],
        [l("easy_money_period.weekly"), 'weekly'],
        [l("easy_money_period.yearly"), 'yearly']],
      value)
  end

  def easy_money_time_entries_to_csv(project_entries, issues, easy_money_settings)
    encoding = l(:general_csv_encoding)
    decimal_separator = l(:general_csv_decimal_separator)
    export = FCSV.generate(:col_sep => l(:general_csv_separator)) do |csv|
      headers = []

      headers << l(:field_project)
      headers << l(:field_issue)
      headers << l(:field_spent_on)
      headers << l(:field_user)
      headers << l(:field_activity)
      headers << l(:field_spent_hours)
      EasyMoneyRateType.active.each do |rate_type|
        headers << rate_type.translated_name
      end

      csv << headers.collect {|c| Redmine::CodesetUtil.safe_from_utf8(c, encoding) }

      project_entries.each do |time_entry|
        fields = []

        fields << time_entry.project.name
        fields << 'N/A'
        fields << format_date(time_entry.spent_on)
        fields << time_entry.user.name
        fields << time_entry.activity.name
        fields << time_entry.hours.to_s.gsub('.', decimal_separator)

        EasyMoneyRateType.active.each do |rate_type|
          fields << time_entry_expense_per_rate_type(time_entry.project, time_entry, rate_type, :format_price => false).to_s.gsub('.', decimal_separator)
        end

        csv << fields.collect {|c| Redmine::CodesetUtil.safe_from_utf8(c, encoding) }
      end

      issues.each do |issue|
        issue.time_entries.each do |time_entry|
          fields = []

          fields << issue.project.name
          fields << issue.subject
          fields << format_date(time_entry.spent_on)
          fields << time_entry.user.name
          fields << time_entry.activity.name
          fields << time_entry.hours.to_s.gsub('.', decimal_separator)

          EasyMoneyRateType.active.each do |rate_type|
            fields << time_entry_expense_per_rate_type(issue.project, time_entry, rate_type, :format_price => false).to_s.gsub('.', decimal_separator)
          end

          csv << fields.collect {|c| Redmine::CodesetUtil.safe_from_utf8(c, encoding) }
        end
      end
    end
    export
  end

  def render_api_easy_money_entity(api, easy_money_entity)
    api.id(easy_money_entity.id)
    api.entity_type(easy_money_entity.entity_type)
    api.entity_id(easy_money_entity.entity_id)
    api.price1(easy_money_entity.price1)
    api.price2(easy_money_entity.price2)
    api.vat(easy_money_entity.vat)
    api.spent_on(easy_money_entity.spent_on)
    api.description(easy_money_entity.description)
    api.name(easy_money_entity.name)
    api.version_id(easy_money_entity.version_id)

    render_api_custom_values(easy_money_entity.visible_custom_field_values, api)
  end

  def render_api_easy_money_expected_expense(api, easy_money_expected_expense)
    api.easy_money_expected_expense do
      render_api_easy_money_entity(api, easy_money_expected_expense)
    end
  end

  def render_api_easy_money_expected_revenue(api, easy_money_expected_revenue)
    api.easy_money_expected_revenue do
      render_api_easy_money_entity(api, easy_money_expected_revenue)
    end
  end

  def render_api_easy_money_other_expense(api, easy_money_other_expense)
    api.easy_money_other_expense do
      render_api_easy_money_entity(api, easy_money_other_expense)
    end
  end

  def render_api_easy_money_other_revenue(api, easy_money_other_revenue)
    api.easy_money_other_revenue do
      render_api_easy_money_entity(api, easy_money_other_revenue)
    end
  end

  def render_api_easy_money_expected_expenses(api, easy_money_expected_expenses, entity_count, offset, limit)
    api.array :easy_money_expected_expenses, api_meta(:total_count => entity_count, :offset => offset, :limit => limit) do
      easy_money_expected_expenses.each do |group, attributes|
        attributes[:entities].each do |easy_money_expected_expense|
          render_api_easy_money_expected_expense(api, easy_money_expected_expense)
        end
      end
    end
  end

  def render_api_easy_money_expected_revenues(api, easy_money_expected_revenues, entity_count, offset, limit)
    api.array :easy_money_expected_revenues, api_meta(:total_count => entity_count, :offset => offset, :limit => limit) do
      easy_money_expected_revenues.each do |group, attributes|
        attributes[:entities].each do |easy_money_expected_revenue|
          render_api_easy_money_expected_revenue(api, easy_money_expected_revenue)
        end
      end
    end
  end

  def render_api_easy_money_other_expenses(api, easy_money_other_expenses, entity_count, offset, limit)
    api.array :easy_money_other_expenses, api_meta(:total_count => entity_count, :offset => offset, :limit => limit) do
      easy_money_other_expenses.each do |group, attributes|
        attributes[:entities].each do |easy_money_other_expense|
          render_api_easy_money_other_expense(api, easy_money_other_expense)
        end
      end
    end
  end

  def render_api_easy_money_other_revenues(api, easy_money_other_revenues, entity_count, offset, limit)
    api.array :easy_money_other_revenues, api_meta(:total_count => entity_count, :offset => offset, :limit => limit) do
      easy_money_other_revenues.each do |group, attributes|
        attributes[:entities].each do |easy_money_other_revenue|
          render_api_easy_money_other_revenue(api, easy_money_other_revenue)
        end
      end
    end
  end

  def render_api_easy_money_rate_priorities(api, project)
    api.easy_money_rate_priorities do
      EasyMoneyRateType.active.each do |rate_type|
        api.easy_money_rate_type do
          api.id(rate_type.id)
          api.name(rate_type.translated_name)
          EasyMoneyRatePriority.rate_priorities_by_rate_type_and_project(rate_type.id, project.id).each do |rate_priority|
            api.easy_money_rate_priority do
              api.id(rate_priority.id)
              api.entity(l("easy_money_entity.#{rate_priority.entity_type.underscore}"))
              api.position(rate_priority.position)
            end
          end
        end
      end
    end
  end

  private

  # Return n non-breaking spaces.
  def nbsp(n)
    ('&nbsp;' * n).html_safe
  end

  def time_entry_expense_per_rate_type(project, time_entry, rate_type, options = {})
    price = ''
    expense = time_entry.easy_money_time_entry_expenses.find(:first, :conditions => {:rate_type_id => rate_type.id})
    if expense
      price = options[:format_price] ? format_easy_money_price(expense.price, project) : expense.price
    else
      price = 'N/A'
    end
    price
  end


end
