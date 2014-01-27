module EasyMoney
  class Hooks < Redmine::Hook::ViewListener

    render_on :view_projects_copy, :partial => 'projects/copy_module_easy_money'
    render_on :view_project_mass_copy_select_actions, :partial => 'project_mass_copy/copy_easy_money_rates'
    render_on :view_issue_sidebar_issue_info_after_menu_more, :partial => 'issues/easy_money_issue_sidebar_issue_info_after_menu_more'
    render_on :view_versions_show_contextual, :partial => 'versions/easy_money_view_versions_show_contextual'

    def controller_templates_create_project_from_template(context={})
      if context[:params][:template] && context[:params][:template][:inherit_easy_money_settings]
        context[:saved_projects].each do |p|
          p.inherit_easy_money_settings = true
          p.copy_easy_money_settings_from_parent
        end
      end
    end

    def helper_options_for_default_project_page(context={})
      default_pages, enabled_modules, selected = context[:default_pages], context[:enabled_modules], context[:selected]
      default_pages << 'easy_money' if enabled_modules && enabled_modules.include?('easy_money')
    end

    def helper_project_settings_tabs(context={})
      project = context[:project]
      context[:tabs] << {:name => 'easymoney', :url => { :controller => 'easy_money_settings', :action => 'project_settings', :project_id => project}, :label => :label_easy_money_settings, :redirect_link => true} if project.module_enabled?(:easy_money)
    end

    def helper_entity_attribute_helper_format_time_entry_attribute(context={})
      attribute = context[:attribute]
      rate_types = EasyMoneyRateType.active.collect{|r| (EasyMoneyTimeEntryExpense::EASY_QUERY_PREFIX  + r.name).to_sym }
      if rate_types.include?(attribute.name)
        unless context[:value]
          return 'N/A'
        else
          format_easy_money_price(context[:value].try(:to_f), context[:entity] && context[:entity].project, :round => true)
        end
      end
    end

    def model_project_copy_additionals(context={})
      project = context[:source_project]
      context[:to_be_copied] << 'easy_money' if project.module_enabled?('easy_money')
    end

    # toto funguje pouze, kdyz v administraci existuje projekt a vypneme a zapneme penize
    def model_project_enabled_module_changed(context={})
      project = context[:project]
      unless project.id.nil?
        EasyMoneyRatePriority.rate_priorities_by_project(nil).copy_to(project) if project.module_enabled?(:easy_money)
      end
    end

    # toto funguje pouze v pripade, ze dany projekt kopiruju
    def model_project_copy_before_save(context={})
      source_project = context[:source_project]
      destination_project = context[:destination_project]
      if source_project.module_enabled?(:easy_money)
        EasyMoneyRatePriority.delete_all(["project_id = ?", destination_project.id])
        EasyMoneyRatePriority.rate_priorities_by_project(source_project).copy_to(destination_project)
      end
    end

    def view_project_budgetsheet_table_header(context={})
      s = ''
      context[:additional_project_head_columns] ||= []
      EasyMoneyRateType.active.each do |rate_type|
        s << '<th width="10%">' + l("easy_money_rate_type.#{rate_type.name}") + '</th>'
        context[:total_sum] << 0.0 unless context[:total_sum].nil?
        context[:additional_project_head_columns] << l("easy_money_rate_type.#{rate_type.name}")
      end
      return s
    end

    def view_project_budgetsheet_table_row(context={})
      entry = context[:entry]
      s = ''
      context[:additional_project_body_columns] ||= []
      if entry.project.easy_money_settings && entry.project.easy_money_settings.show_rate?('all')
        EasyMoneyRateType.active.each_with_index do |rate_type, i|
          expense = entry.easy_money_time_entry_expenses.easy_money_time_entries_by_rate_type(rate_type)
          if expense.empty?
            s << '<td align="center"> N/A </td>'
            context[:total_sum][i] = 0.0 unless context[:total_sum].nil?
            context[:additional_project_body_columns] << 'N/A'
          else
            s << '<td align="center">' + format_easy_money_price(expense.first.price, entry.project) + '</td>'
            context[:total_sum][i] += expense.first.price unless context[:total_sum].nil?
            context[:additional_project_body_columns] << expense.first.price
          end
        end
      else
        expense = entry.easy_money_time_entry_expenses.easy_money_time_entries_by_rate_type(EasyMoneyRateType.active.find(:first))
        if expense.empty?
          s << '<td align="center"> N/A </td>'
          context[:total_sum][0] = 0.0 unless context[:total_sum].nil?
          context[:additional_project_body_columns] << 'N/A'
        else
          s << '<td align="center">' + format_easy_money_price(expense.first.price, entry.project) + '</td>'
          context[:total_sum][0] += expense.first.price unless context[:total_sum].nil?
          context[:additional_project_body_columns] << expense.first.price
        end
        s << '<td align="center"> N/A </td>'
        context[:total_sum][1] = 0.0
        context[:additional_project_body_columns] << 'N/A'
      end

      return s
    end

    def view_projects_form_above_custom_fields(context={})
      f = context[:form]
      project = context[:project]
      if project.safe_attribute?('inherit_easy_money_settings')
        content_tag(:p, f.check_box(:inherit_easy_money_settings))
      end
    end

    def controller_projects_new(context={})
      context[:project].inherit_easy_money_settings = true unless context[:params][:project]
    end

    def view_issues_show_journals_top(context={})
      issue, project = context[:issue], context[:project]
      return unless project.module_enabled?(:easy_money) && project.easy_money_settings.use_easy_money_for_issues?
      context[:controller].send(:render_to_string, :partial => 'issues/view_issues_show_journals_top', :locals => context)
    end

    def view_projects_roadmap_version_header_bottom(context={})
      version, project = context[:version], context[:project]
      return unless project.module_enabled?(:easy_money) && project.easy_money_settings.use_easy_money_for_versions?
      context[:controller].send(:render_to_string, :partial => 'versions/projects_roadmap_version_header_bottom', :locals => context)
    end

    def view_versions_show_before_history(context={})
      version, project = context[:version], context[:project]
      return unless project.module_enabled?(:easy_money) && project.easy_money_settings.use_easy_money_for_versions?
      context[:controller].send(:render_to_string, :partial => 'versions/versions_show_before_history', :locals => context)
    end

    def view_issue_sidebar_issue_info_after_menu_more(context={})
      issue = context[:issue]
      project = issue.project
      return unless project.module_enabled?(:easy_money) && project.easy_money_settings.use_easy_money_for_issues?
      context[:controller].send(:render_to_string, :partial => 'issues/easy_money_issue_sidebar_issue_info_after_menu_more', :locals => context)
    end

    def view_templates_create_project_from_template(context={})
      html = label_tag('template[inherit_easy_money_settings]', l(:field_inherit_easy_money_settings))
      html << check_box_tag('template[inherit_easy_money_settings]', '1', true)
      content_tag(:p, html)
    end

    def view_versions_show_contextual(context={})
      version, project = context[:version], context[:project]
      return unless project.module_enabled?(:easy_money) && project.easy_money_settings.use_easy_money_for_versions?
      context[:controller].send(:render_to_string, :partial => 'versions/easy_money_view_versions_show_contextual', :locals => context)
    end

    def view_easy_printable_templates_token_list_bottom(context={})
      return if context[:section] != :plugins
      context[:controller].send(:render_to_string, :partial => 'easy_printable_templates/easy_money_view_easy_printable_templates_token_list_bottom', :locals => context)
    end

    def easy_reports_contingency_table_data_source_add_fields(context={})
      data_source = context[:data_source]

      require_dependency 'easy_money_easy_reports_project_contingency_fields'

      data_source.add_fields(
        EasyReports::ContingencyFields::TimeEntryInternalRateField.new(data_source), EasyReports::ContingencyFields::TimeEntryExternalRateField.new(data_source),
        EasyReports::ContingencyFields::EasyMoneyOtherRevenueIdField.new(data_source), EasyReports::ContingencyFields::EasyMoneyOtherRevenueNameField.new(data_source), EasyReports::ContingencyFields::EasyMoneyOtherRevenuePrice1Field.new(data_source), EasyReports::ContingencyFields::EasyMoneyOtherRevenuePrice2Field.new(data_source),
        EasyReports::ContingencyFields::EasyMoneyOtherExpenseIdField.new(data_source), EasyReports::ContingencyFields::EasyMoneyOtherExpenseNameField.new(data_source), EasyReports::ContingencyFields::EasyMoneyOtherExpensePrice1Field.new(data_source), EasyReports::ContingencyFields::EasyMoneyOtherExpensePrice2Field.new(data_source),
        EasyReports::ContingencyFields::ProjectExpectedHoursField.new(data_source), EasyReports::ContingencyFields::ProjectExpectedPayrollExpenseField.new(data_source),
        EasyReports::ContingencyFields::ProjectExpectedExpenseIdField.new(data_source), EasyReports::ContingencyFields::ProjectExpectedExpenseNameField.new(data_source), EasyReports::ContingencyFields::ProjectExpectedExpensePrice1Field.new(data_source), EasyReports::ContingencyFields::ProjectExpectedExpensePrice2Field.new(data_source),
        EasyReports::ContingencyFields::ProjectExpectedRevenueIdField.new(data_source), EasyReports::ContingencyFields::ProjectExpectedRevenueNameField.new(data_source), EasyReports::ContingencyFields::ProjectExpectedRevenuePrice1Field.new(data_source), EasyReports::ContingencyFields::ProjectExpectedRevenuePrice2Field.new(data_source),
        EasyReports::ContingencyFields::ProjectRecoveryField.new(data_source), EasyReports::ContingencyFields::ProjectTimeEntryAverageHourlyExpenseField.new(data_source), EasyReports::ContingencyFields::ProjectOtherProfitField.new(data_source)
      )

      EasyMoneyOtherRevenueCustomField.all.each do |custom_field|
        data_source.add_field(EasyReports::ContingencyFields::EasyMoneyOtherRevenueCustomFieldReports.new(data_source, custom_field))
      end

      EasyMoneyOtherExpenseCustomField.all.each do |custom_field|
        data_source.add_field(EasyReports::ContingencyFields::EasyMoneyOtherExpenseCustomFieldReports.new(data_source, custom_field))
      end
    end

  end
end
