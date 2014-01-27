module EasyExtensions
  class Hooks < Redmine::Hook::ViewListener

    render_on :view_users_form, :partial => "users/additional_fields"
    render_on :view_easy_page_templates_index_additional_actions, :partial => "easy_page_templates/template_actions"
    render_on :view_my_account_contextual, :partial => 'my/avatar'
    render_on :view_layouts_base_body_bottom, :partial => 'layouts/layouts_base_body_bottom'
    render_on :view_enumerations_index_bottom, :partial => 'easy_attendance_activities/list'
    render_on :view_easy_query_filter_settings_bottom, :partial => 'gantts/query_additional_settings'

    def controller_enumerations_create_after_save(context={})
      enumeration_after_save(context)
    end

    def controller_enumerations_edit_after_save(context={})
      enumeration_after_save(context)
    end

    def controller_easy_page_layout_layout_from_template_to_all(context={})
      page_template, page, actions = context[:page_template], context[:page], context[:actions]

      if actions.include?('projects') && page.page_name == 'project-overview'
        Project.non_templates.each do |project|
          EasyPageZoneModule.create_from_page_template(page_template, nil, project.id)
        end
      end
    end

    def controller_issues_bulk_edit_before_save(context={})
      issue = context[:issue]
      old_version = issue.fixed_version_id_was && Version.find(issue.fixed_version_id_was)
      if old_version && (issue.due_date_was != old_version.due_date)
        issue.safe_attributes = {:due_date => issue.due_date_was}
      end
    end

    def controller_projects_create_after_save(context={})
      project = context[:project]
      if EasyPage.table_exists? && EasyPageTemplate.table_exists? && EasyPageZoneModule.table_exists?
        project_overview = EasyPage.page_project_overview
        project_overview_template = EasyPageTemplate.default_template_for_page(project_overview)
        if project_overview_template
          EasyPageZoneModule.create_from_page_template(project_overview_template, nil, project.id)
        end
      end
    end

    def controller_projects_new(context={})
      context[:project].inherit_time_entry_activities = true unless context[:params][:project]
    end

    def controller_templates_create_project_from_template(context={})
      if context[:params][:template] && context[:params][:template][:inherit_time_entry_activities]
        context[:saved_projects].each do |p|
          p.inherit_time_entry_activities = true
          p.copy_time_entry_activities_from_parent
        end
      end
    end

    def controller_timelog_edit_before_save(context={})
      time_entry, params = context[:time_entry], context[:params]

      if params[:new_project_id]
        time_entry.project = Project.find(params[:new_project_id])
      end
    end

    def model_group_user_added_after_save(context={})
      user = context[:user]
      user.update_attributes(:cached_group_names => user.groups.collect(&:name).sort.join(', '))
    end

    def model_group_user_removed_after_destroy(context={})
      user = context[:user]
      user.update_attributes(:cached_group_names => user.groups.collect(&:name).sort.join(', '))
    end

    def model_mail_handler_receive_issue_created(context={})
      mail_handler, issue = context[:mail_handler], context[:issue]

      if easy_rake_task_info_detail = mail_handler.class.handler_options[:easy_rake_task_info_detail]
        easy_rake_task_info_detail.entity = issue
        easy_rake_task_info_detail.save
      end
    end

    def view_custom_field_field_format_settings(context={})
      cf = context[:custom_field]
      case cf.field_format
      when 'easy_lookup'
        context[:controller].send(:render_to_string, :partial => "custom_fields/field_format_easylookup_settings", :locals => context)
      when 'autoincrement'
        context[:controller].send(:render_to_string, :partial => "custom_fields/field_format_autoincrement_settings", :locals => context)
      when 'easy_rating'
        context[:controller].send(:render_to_string, :partial => "custom_fields/field_format_easy_rating_settings", :locals => context)
      end
    end

    def view_enumerations_form_bottom(context={})
      enumeration = context[:enumeration]
      if enumeration.is_a?(DocumentCategory)
        context[:controller].send(:render_to_string, {:locals => context}.merge(:partial => 'documents/additional_category_form', :locals => {:enumeration => enumeration }))
      elsif enumeration.is_a?(TimeEntryActivity) || enumeration.is_a?(IssuePriority)
        choose_color_scheme(:enumeration, enumeration)
      end

    end

    def view_issue_statuses_form(context={})
      issue_status = context[:issue_status]
      choose_color_scheme(:issue_status, issue_status)
    end

    def view_journal_show_description_bottom(context={})
      return nil unless EasySetting.value('show_journal_id')
      
      journal = context[:journal]
      issue = context[:issue]
      issue ||= journal.issue

      link_journal_id = link_to(journal.id, {:controller => 'issues', :action => 'show', :id => issue.id, :anchor => "change-#{journal.id}"},
        :class => 'journal', :title => "#{truncate(h(issue.subject), :length => 100)} (#{issue.status.name})")

      content_tag(:span , link_journal_id.html_safe, :class => 'journal-id')
    end
    
    def view_issues_show_details_bottom(context={})
      issue = context[:issue]
      return unless issue.easy_is_repeating? && issue.easy_next_start
      context[:controller].send(:render_to_string, :partial => 'issues/easy_repeating_view_issues_show_details_bottom', :locals => context)
    end

    def view_projects_form_above_custom_fields(context={})
      f = context[:form]
      project = context[:project]
      if project.safe_attribute?('inherit_time_entry_activities')
        content_tag(:p, f.check_box(:inherit_time_entry_activities))
      end
    end

    def view_templates_create_project_from_template(context={})
      html = label_tag('template[inherit_time_entry_activities]', l(:field_inherit_time_entry_activities))
      html << check_box_tag('template[inherit_time_entry_activities]', '1', true)
      content_tag(:p, html)
    end


    private

    def enumeration_after_save(context={})
      enumeration, params = context[:enumeration], context[:controller].params
      return unless enumeration.respond_to?(:easy_permissions)

      if params['easy_permission']
        if params['easy_permission']['read']
          ep = enumeration.easy_permissions.detect{|x| x.name == 'read'} || enumeration.easy_permissions.new(:name => 'read')
          ep.role_list = params['easy_permission']['read']['custom_roles'] == '0' ? [] : (params['easy_permission']['read']['role_list'] || []).collect(&:to_i)
          ep.save!
        end

        if params['easy_permission']['manage']
          ep = enumeration.easy_permissions.detect{|x| x.name == 'manage'} || enumeration.easy_permissions.new(:name => 'manage')
          ep.role_list = params['easy_permission']['manage']['custom_roles'] == '0' ? [] : (params['easy_permission']['manage']['role_list'] || []).collect(&:to_i)
          ep.save!
        end
      end
    end

    def choose_color_scheme(name, entity)
      s = Array.new

      s << label_tag( "#{name}_easy_color_scheme", l(:label_easy_color_schemes))
      s << easy_color_scheme_select_tag( "#{name}[easy_color_scheme]", :selected => entity.easy_color_scheme, :class => entity.easy_color_scheme)
      if EasySetting.value('issue_color_scheme_for') != entity.class.name.underscore
        s << '<p class="color-red">'
        s << l(:easy_color_scheme_not_available, :current => l("label_#{EasySetting.value('issue_color_scheme_for')}_plural") )
        s << link_to(l(:label_my_page_issue_query_new_link), {:controller => 'settings', :tab => 'issues'})
        s << '</p>'
      end
      content_tag(:p, s.join("\n").html_safe)
    end

  end
end