module EntityAttributeHelper

  include ERB::Util

  # Returns a formatted html value for query column
  # - entity_class - associated class of entity (query.entity), e.g.: Issue, Project, User, ...
  # - attribute - EasyEntityAttribute to format
  # - unformatted_value - Unformatted value of associated entity, which needed formatted
  # - options - :no_link => true - no html links will be rendered
  #           - :entity => associated entity, eg, issue, project, user, time_entry, ...
  #           - :no_html => passed to custom fields to do not display any html tags
  #           - :project => project from query, which helps to decide in some cases to take an specific setting
  #
  # This method looks for a concrete entity method or format_html_default_column is called
  def format_html_entity_attribute(entity_class, attribute, unformatted_value, options={})
    return nil if entity_class.nil? || attribute.nil?
    attribute = ensure_attribute(attribute, options)
    options[:no_link] = attribute.no_link unless options.has_key?(:no_link)

    if attribute.is_a?(EasyEntityCustomAttribute) && options[:entity] && attribute.assoc
      options[:entity] = options[:entity].send(attribute.assoc)
      entity_class = options[:entity].class
    end

    format_html_entity_attribute_method = "format_html_#{entity_class.name.underscore}_attribute".to_sym

    if respond_to?(format_html_entity_attribute_method)
      formatted_value = send(format_html_entity_attribute_method, entity_class, attribute, unformatted_value, options)
    else
      formatted_value = format_html_default_entity_attribute(attribute, unformatted_value, options)
    end

    return (formatted_value.to_s || '').html_safe
  end

  # Returns a formatted value for query column
  # - column - query column to format
  # - entity - associated instance of entity, e.g.: issue, project, user, ...
  # - options
  #
  # This method looks for a concrete entity method or format_default_column is called
  def format_entity_attribute(entity_class, attribute, unformatted_value, options={})
    return nil if entity_class.nil? || attribute.nil?
    attribute = ensure_attribute(attribute, options)
    format_entity_attribute_method = "format_#{entity_class.name.underscore}_attribute".to_sym

    if respond_to?(format_entity_attribute_method)
      formatted_value = send(format_entity_attribute_method, entity_class, attribute, unformatted_value, options)
    else
      formatted_value = format_default_entity_attribute(attribute, unformatted_value, options)
    end

    return formatted_value
  end

  # protected

  def format_html_issue_attribute(entity_class, attribute, unformatted_value, options={})
    value = format_entity_attribute(entity_class, attribute, unformatted_value, options)

    if (attribute.is_a?(EasyEntityCustomAttribute) && options[:entity])
      cv = options[:entity].visible_custom_field_values.detect {|v| v.custom_field_id == attribute.custom_field.id}
      show_value(cv, options)
    else
      case attribute.name
      when :project
        if options[:entity]
          link_to_project(options[:entity].project)
        else
          h(value)
        end
      when :subject
        if options.has_key?(:wrap)
          value = value.scan(/(.{1,#{options[:wrap]}})/).flatten.join('<br/>').html_safe
        end
        if options[:no_link]
          h(value)
        else
          link_to(h(value), options[:entity], :data => {:entity_type => 'Issue', :entity_id => options[:entity].id, :handler => true})
        end
      when :relations
        if value && options[:entity]
          value.collect {|relation| "#{l(relation.label_for(options[:entity]))} #{link_to(relation.other_issue(options[:entity]))}"}.join(', ').html_safe
        end
      when :done_ratio
        if options[:no_progress_bar]
          value
        else
          progress_bar(value, :width => '50px', :title => "#{l(:label_done)} #{value} %")
        end
      when :description
        textilizable(value, {:headings => false})
      when :created_on
        EasySetting.value('issue_created_on_date_format') == 'date' ? format_date(value.to_date) : value
      when :sum_of_timeentries, :remaining_timeentries, :estimated_hours
        format_hours(value.to_f)
      when :spent_estimated_timeentries
        n = value.to_f > 100 ? -1 : value.to_f
        format_number(n, "%d %" % value)
      when :category
        if options[:entity] && value
          render_issue_category_with_tree(value)
        else
          h(value)
        end
      when :due_date
        content_tag :span, h(value), {:class => 'multieditable', :data => {
            :name => 'issue[due_date]',
            :type => 'dateui',
            :value => unformatted_value.to_s
          }
        }
      when :start_date
        content_tag :span, h(value), {:class => 'multieditable', :data => {
            :name => 'issue[start_date]',
            :type => 'dateui',
            :value => unformatted_value.to_s
          }
        }
      when :priority
        content_tag :span, h(value), {:class => 'multieditable', :data => {
            :name => 'issue[priority_id]',
            :type => 'select',
            :value => options[:entity].try(:priority_id),
            :source => url_for(:controller => 'easy_auto_completes', :action => 'issue_priorities')
          }
        }
      when :status
        content_tag :span, h(value), {:class => 'multieditable', :data => {
            :name => 'issue[status_id]',
            :type => 'select',
            :value => options[:entity].try(:status_id),
            :source => url_for(:controller => 'easy_auto_completes', :action => 'allowed_issue_statuses', :issue_id => options[:entity].try(:id))
          }
        }
      when :assigned_to
        content_tag :span, h(value), {:class => 'multieditable', :data => {
            :name => 'issue[assigned_to_id]',
            :type => 'select',
            :value => options[:entity].try(:assigned_to_id),
            :source => url_for(:controller => 'easy_auto_completes', :action => 'assignable_users', :issue_id => options[:entity].try(:id))
          }
        }
      else
        h(value)
      end
    end
  end

  def format_issue_attribute(entity_class, attribute, unformatted_value, options={})
    value = format_default_entity_attribute(attribute, unformatted_value, options)

    value = case attribute.name
    when :watchers
      if !unformatted_value.empty?
        unformatted_value.collect{|w| w.user.name}.join(', ')
      else
        l(:label_nobody)
      end
    when :subject
      if options[:entity] && options[:entity].easy_is_repeating
        value + ' ' + l(:label_easy_issue_subject_reccuring_suffix)
      else
        value
      end
    else
      value
    end

    value
  end

  def format_html_project_attribute(entity_class, attribute, unformatted_value, options={})
    value = format_entity_attribute(entity_class, attribute, unformatted_value, options)

    if (attribute.is_a?(EasyEntityCustomAttribute) && options[:entity])
      cv = options[:entity].visible_custom_field_values.detect {|v| v.custom_field_id == attribute.custom_field.id}
      show_value(cv, options)
    else
      case attribute.name
      when :name
        if options[:no_link] || (options[:entity] && (options[:entity].archived? || !User.current.allowed_to?(:view_project, options[:entity])))
          h(options[:entity])
        else
          link_to_project(options[:entity])
        end
      when :done_ratio, :completed_percent
        progress_bar(value, :width => '80px')
      when :users
        value.sort.collect{|u| link_to(u.to_s, u)}.join(', ')
      when :description
        textilizable(value, {:headings => false})
      when :sum_of_timeentries, :remaining_timeentries
        format_hours(value)
      when :sum_estimated_hours
        format_hours(value || 0.0)
      else
        h(value)
      end
    end
  end

  def format_project_attribute(entity_class, attribute, unformatted_value, options={})
    value = format_default_entity_attribute(attribute, unformatted_value, options)

    value = case attribute.name
    when :status
      case value
      when Project::STATUS_ACTIVE
        l(:project_status_active)
      when Project::STATUS_CLOSED
        l(:project_status_closed)
      when Project::STATUS_ARCHIVED
        l(:project_status_archived)
      when Project::STATUS_PLANNED
        l(:project_status_planned)
      end
    when :sum_of_timeentries, :remaining_timeentries, :estimated_hours
      value.round(2) if value
    else
      value
    end

    value
  end

  def format_html_version_attribute(entity_class, attribute, unformatted_value, options={})
    value = format_entity_attribute(entity_class, attribute, unformatted_value, options)

    if (attribute.is_a?(EasyEntityCustomAttribute) && options[:entity])
      cv = options[:entity].visible_custom_field_values.detect {|v| v.custom_field_id == attribute.custom_field.id}
      show_value(cv, options)
    else
      case attribute.name
      when :name
        if options[:no_link]
          h(value)
        else
          link_to(h(value), :controller => 'versions', :action => 'show', :id => options[:entity])
        end
      when :description
        truncate_html(textilizable(value, {:headings => false}), 255)
      when :completed_percent
        progress_bar(options[:entity] ? [options[:entity].closed_percent, value] : value, :width => '80px', :legend => ('%0.0f%' % value))
      else
        h(value)
      end
    end
  end

  def format_version_attribute(entity_class, attribute, unformatted_value, options={})
    value = format_default_entity_attribute(attribute, unformatted_value, options)

    case attribute.name
    when :status
      l("version_status_#{value}")
    when :sharing
      format_version_sharing(value)
    else
      if value.nil?
        l(:label_none)
      else
        value
      end
    end
  end

  def format_html_easy_attendance_attribute(entity_class, attribute, unformatted_value, options={})
    value = format_entity_attribute(entity_class, attribute, unformatted_value, options)

    if (options[:entity] && options[:entity].is_a?(EasyEntityCustomAttribute))
      cv = options[:entity].visible_custom_field_values.detect {|v| v.custom_field_id == attribute.custom_field.id}
      show_value(cv)
    else
      case attribute.name
      when :spent_time
        if options[:entity] && value && options[:entity].working_time
          format_number(value - options[:entity].working_time, format_hours(value)) if value
        elsif value
          format_hours(value)
        end
      when :working_time
        format_hours(value) if value
      when :description
        textilizable(value)
      else
        h(value)
      end
    end
  end

  def format_easy_attendance_attribute(entity_class, attribute, unformatted_value, options={})
    value = format_default_entity_attribute(attribute, unformatted_value, options)

    case attribute.name
    when :easy_attedance_activity
      value.to_s
    when :spent_time
      value = value.to_f if value.is_a?(String)
      value.round(2) if value
    else
      value
    end
  end

  def format_user_attribute(entity_class, attribute, unformatted_value, options={})
    value = format_default_entity_attribute(attribute, unformatted_value, options)

    case attribute.name
    when :easy_user_type
      case value
      when User::EASY_USER_TYPE_INTERNAL
        l(:'user.easy_user_type.internal')
      when User::EASY_USER_TYPE_EXTERNAL
        l(:'user.easy_user_type.external')
      end
    else
      value
    end
  end

  def format_html_user_attribute(entity_class, attribute, unformatted_value, options={})
    value = format_entity_attribute(entity_class, attribute, unformatted_value, options)

    if (attribute.is_a?(EasyEntityCustomAttribute) && options[:entity])
      cv = options[:entity].visible_custom_field_values.detect {|v| v.custom_field_id == attribute.custom_field.id}
      show_value(cv, options)
    else
      case attribute.name
      when :name
        if options[:no_link]
          h(value)
        else
          link_to(h(value), :controller => 'users', :action => 'show', :id => options[:entity])
        end
      when :login
        if options[:no_link]
          h(value)
        else
          link_to(value, :controller => 'users', :action => 'show', :id => options[:entity])
        end
      when :mail
        mail_to value
      when :easy_global_rating
        if value && value.value
          rating_stars(value.value)
        end
      else
        h(value)
      end
    end
  end

  def format_html_group_attribute(entity_class, attribute, unformatted_value, options={})
    value = format_entity_attribute(entity_class, attribute, unformatted_value, options)

    if (attribute.is_a?(EasyEntityCustomAttribute) && options[:entity])
      cv = options[:entity].visible_custom_field_values.detect {|v| v.custom_field_id == attribute.custom_field.id}
      show_value(cv, options)
    else
      case attribute.name
      when :lastname
        if options[:no_link]
          h(value)
        else
          link_to(h(value), :controller => 'groups', :action => 'show', :id => options[:entity])
        end
      else
        h(value)
      end
    end
  end

  def format_html_document_attribute(entity_class, attribute, unformatted_value, options={})
    value = format_entity_attribute(entity_class, attribute, unformatted_value, options)

    if (attribute.is_a?(EasyEntityCustomAttribute) && options[:entity])
      cv = options[:entity].visible_custom_field_values.detect {|v| v.custom_field_id == attribute.custom_field.id}
      show_value(cv, options)
    else
      case attribute.name
      when :title
        if options[:no_link]
          h(value)
        else
          link_to(h(value), :controller => 'documents', :action => 'show', :id => options[:entity])
        end
      when :description
        textilizable(value, {:headings => false})
      else
        h(value)
      end
    end
  end

  def format_html_time_entry_attribute(entity_class, attribute, unformatted_value, options={})
    value = format_entity_attribute(entity_class, attribute, unformatted_value, options)

    if (attribute.is_a?(EasyEntityCustomAttribute) && options[:entity])
      cv = options[:entity].visible_custom_field_values.detect {|v| v.custom_field_id == attribute.custom_field.id}
      show_value(cv, options)
    else
      case attribute.name
      when :issue
        if value.is_a?(Issue)
          tooltip_id = "#{dom_id(value)}_#{Redmine::Utils.random_hex(8)}"
          content_tag :div, :class => 'tooltip', :id => tooltip_id do
            a = link_to(value.subject, {:controller => 'issues', :action => 'show', :id => value})
            a << ''
            a << javascript_tag( "$('##{tooltip_id}').qtip({
              content: '#{j content_tag( :span, render_issue_tooltip(value), :class => 'tip')}',
              hide: {
                fixed: true,
                delay: 500
              },
              position: {
                adjust: {
                  screen: true
                  }
                }
              })")
            a
          end
        else
          value
        end
      when :comments
        content_tag :div, (value || '').html_safe
      when :hours, :estimated_hours
        (html_hours(value) + "&nbsp;h".html_safe).html_safe if value
      when :user_roles
        value.collect{|r| r.name}.join(', ')
      else
        h(value)
      end
    end

  end

  def format_time_entry_attribute(entity_class, attribute, unformatted_value, options={})
    value = format_default_entity_attribute(attribute, unformatted_value, options)

    case attribute.name
    when :issue
      unless value
        l(:label_none)
      else
        value
      end
    when :hours, :estimated_hours
      ('%.2f' % value) if value
    when :easy_range_from
      if value
        begin
          datetime = value.to_datetime
          hour_to_string(datetime.hour) + ':' + min_to_string(datetime.min)
        rescue
          value
        end
      end
    when :easy_range_to
      if value
        begin
          datetime = value.to_datetime
          hour_to_string(datetime.hour) + ':' + min_to_string(datetime.min)
        rescue
          value
        end
      end
    else
      hooked = call_hook(:helper_entity_attribute_helper_format_time_entry_attribute, {:value => value, :attribute => attribute, :entity => options[:entity]})

      if hooked.is_a?(Array)
        hooked.compact!
        value = hooked.first if hooked.present?
      else
        value = hooked if hooked.present?
      end

      return value
    end

  end

  private

  def ensure_attribute(attribute, options={})
    unless attribute.is_a?(EasyEntityAttribute)
      if attribute.start_with?('link_with_')
        attribute = EasyEntityAttribute.new(attribute.sub('link_with_', ''), options)
      else
        attribute = EasyEntityAttribute.new(attribute, {:no_link => true}.merge(options))
      end
    end
    attribute
  end

  def format_html_default_entity_attribute(attribute, unformatted_value, options={})
    value = format_default_entity_attribute(attribute, unformatted_value, options)

    return value
  end

  def format_default_entity_attribute(attribute, unformatted_value, options={})
    if options[:allow_avatar] && unformatted_value.class.name == 'User'
      value = avatar(unformatted_value, :size => '40').to_s + unformatted_value.name
    else
      value = case unformatted_value.class.name
      when 'Time'
        format_time(unformatted_value)
      when 'Date'
        format_date(unformatted_value)
      when 'TrueClass'
        l(:general_text_Yes)
      when 'FalseClass'
        l(:general_text_No)
      else
        unformatted_value
      end
    end

    value
  end

end
