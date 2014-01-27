class EpmIssuesCreateNew < EasyPageModule

  def category_name
    @category_name ||= 'issues'
  end

  def permissions
    @permissions ||= [:add_issues]
  end

  def get_show_data(settings, user, page_context = {})
    issue = page_context[:issue] || Issue.new
    fields = (settings['selected_fields'] ||= {})
    settings['show_fields_option'] ||= 'all'
    settings['enable_text_editor'] ||= '1'
    unless(page_context[:issue])
      last_issue = Issue.visible.where(:author_id => user.id).reorder("#{Issue.table_name}.id DESC").first
      last_project = (last_issue && last_issue.project) || Project.visible(user).non_templates.has_module(:issue_tracking).first
      if settings['show_fields_option'] == 'only_selected' && fields['project_id'] && !fields['project_id']['default_value'].blank?
        issue.project = Project.where(:id => fields['project_id']['default_value']).first || last_project
      else
        issue.project = last_project
      end
      issue.tracker = (issue.project && issue.project.trackers.first)
      issue.start_date ||= Date.today
      issue.author = user
    end
    issue_priorities = IssuePriority.active
    assignable_users = issue.assignable_users
    allowed_statuses = issue.new_statuses_allowed_to(user, true)
    if issue.project
      allowed_trackers = issue.project.trackers
      if fields[:tracker_id] && fields[:tracker_id]['default_value'].is_a?(Array) && fields[:tracker_id]['default_value'].length > 1
        allowed_trackers.select!{|t| fields[:tracker_id]['default_value'].include?(t.id.to_s)}
      end
    end

    issue_default_values_from_settings(issue, fields, settings, assignable_users, issue_priorities, allowed_statuses) unless page_context[:issue]

    #    # for
    #    users_and_groups = [
    #      [l(:label_issue_assigned_to_users), issue.assignable_users.collect{|m| [m.name, m.id]}],
    #      [l(:label_issue_assigned_to_groups), issue.assignable_groups.collect{|m| [m.name, m.id]}]
    #    ]

    #
    #    @issue_data ||= {}
    #    if @issue_data.key?(block_name)
    #      issue = @issue_data[block_name]
    #    else
    #      issue = @easy_page_modules_data[block_name][:issue]
    #    end
    hidden_fields = []
    required_attributes = []
    if settings['show_fields_option'] == 'only_selected'
      hidden_fields = settings['selected_fields'].to_a.select{|f| f[1].is_a?(Hash) && !f[1]['enabled']}.collect{|f| f[0].to_sym}
    elsif settings['show_fields_option'] == 'only_required'
      required_attributes = issue.required_attribute_names
      [:assigned_to_id, :due_date, :attachments].each do |field_to_hide|
        hidden_fields << field_to_hide if !required_attributes.include?(field_to_hide.to_s)
      end
      hidden_fields << :easy_is_repeating
    end

    return {:issue => issue, :settings => settings, :user => user, :issue_priorities => issue_priorities,
      :assignable_users => assignable_users, :allowed_statuses => allowed_statuses,
      :hidden_fields => hidden_fields, :allowed_trackers => allowed_trackers, :only_selected => settings['show_fields_option'] == 'only_selected',
      :required_attributes => required_attributes}
  end

  def get_edit_data(settings, user, page_context={})
    return {:available_fields => available_fields}
  end

  private

    def available_fields
      {
        :subject => {},
        :description => {},
        :project_id => {:label => :field_project},
        :tracker_id => {:label => :field_tracker, :values => Tracker.all},
        :assigned_to_id => {:label => :field_assigned_to, :values => User.active},
        :priority_id => {:label => :field_priority, :values => IssuePriority.all},
        :status_id => {:label => :field_status, :values => IssueStatus.all},
        :start_date => {},
        :due_date => {},
        :attachments => {},
        :easy_is_repeating => {}
      }
    end

    def issue_default_values_from_settings(issue, fields, settings, assignable_users, allowed_priorities, allowed_statuses)
      return if fields.blank? || settings['show_fields_option'] != 'only_selected'

      enabled_normal_fields = ['subject', 'description', 'start_date', 'due_date', 'easy_is_repeating']
      enabled_id_values = {
        'tracker_id' => issue.project && issue.project.tracker_ids || [],
        'assigned_to_id' => assignable_users.collect(&:id),
        'priority_id' => allowed_priorities.collect(&:id),
        'status_id' => allowed_statuses.collect(&:id)
      }
      renames =

      fields.each do |name, options|
        if enabled_normal_fields.include?(name)
          issue.send( name+'=', options['default_value']) if !options['default_value'].blank?

        elsif issue.project && enabled_id_values.keys.include?(name)
          value_id = options['default_value'].blank? ? nil : options['default_value']
          value_id = (name == 'tracker_id' ? value_id.first.to_i : value_id.to_i) if value_id
          issue.send( name+'=', value_id) if enabled_id_values[name].include?(value_id)
        end
      end

    end

end
