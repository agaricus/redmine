module EasyJournalHelper

  def easy_journal_render_history(easy_journals, options={})
    return if easy_journals.nil? || easy_journals.empty?
    options ||= {}
    options[:back_url] = url_for(params)
    journals = ''

    easy_journals.each do |journal|
      details = ''
      details << content_tag(:h4, content_tag('a', '', :name => "note-#{journal.indice}") + authoring(journal.created_on, journal.user, :label => :label_updated_time_by))
      if journal.visible_details.any?
        details << '<ul class="details">'
        easy_journal_details_to_strings(journal.visible_details, false, :entity => options[:entity]).each do |string|
          details << content_tag(:li, string)
        end
        details << '</ul>'
      end
      content = avatar(journal.user) + content_tag(:div, details.html_safe, :class => 'journal-details-container')
      content << content_tag(:div, '', :class => 'clear')
      content << render_notes(journal.journalized, journal, {:reply_links => options[:reply_links], :editable => options[:editable], :back_url => options[:back_url]}) unless journal.notes.blank?
      journals << content_tag(:div, content, :id => "change-#{journal.id}", :class => journal.css_classes)
    end

    if options[:collapsible]
      options[:default_button_state] = true if !options.key?(:default_button_state)
      toggling_container("easy-journal-history#{options[:modul_uniq_id]}", User.current, {:heading => l(:label_history), :default_button_state => options[:default_button_state]}) do
        content_tag(:div, journals.html_safe, :id => 'history-show-bubble', :class => 'bubble')
      end
    else
      content_tag(:div, :id => 'history') do
        content_tag(:fieldset) do
          content_tag(:legend, l(:label_history)) + content_tag(:div, journals.html_safe, :id => 'history-show-bubble', :class => 'bubble easy-journal')
        end
      end
    end
  end

  # if entity is passed as options[:entity], than db queries are saved( 150ms average )
  def easy_journal_details_to_strings(details, no_html=false, options={})
    options[:only_path] = (options[:only_path] == false ? false : true)
    strings = []
    values_by_field = {}
    details.each do |detail|
      if detail.property == 'cf'
        field = detail.custom_field
        if field && field.multiple?
          values_by_field[field] ||= {:added => [], :deleted => []}
          if detail.old_value
            values_by_field[field][:deleted] << detail.old_value
          end
          if detail.value
            values_by_field[field][:added] << detail.value
          end
          next
        end
      end
      strings << show_easy_journal_detail(detail, no_html, options)
    end
    values_by_field.each do |field, changes|
      detail = JournalDetail.new(:property => 'cf', :prop_key => field.id.to_s)
      detail.instance_variable_set "@custom_field", field
      if changes[:added].any?
        detail.value = changes[:added]
        strings << show_easy_journal_detail(detail, no_html, options)
      elsif changes[:deleted].any?
        detail.old_value = changes[:deleted]
        strings << show_easy_journal_detail(detail, no_html, options)
      end
    end
    strings
  end

  # DO NOT USE WITHOUT easy_journal_details_to_strings
  # options:
  # => :no_html = true/false (default je false)
  # => :only_path = true/false (default je true)
  def show_easy_journal_detail(detail, no_html=false, options={})
    only_path = options.key?(:only_path) ? options[:only_path] : true
    multiple = false
    field = detail.prop_key.to_s.gsub(/\_id$/, "")
    label = l(("field_" + field).to_sym)
    unless detail.property == 'cf'
      entity = options[:entity]
      entity ||= detail.journal.journalized

      date_columns = [
        'due_date', 'start_date', 'effective_date'
      ] + entity.journalized_options[:format_detail_date_columns]
      time_columns = entity.journalized_options[:format_detail_time_columns]
      reflection_columns = [
        'project_id', 'parent_id', 'status_id', 'tracker_id', 'assigned_to_id', 'priority_id', 'category_id', 'fixed_version_id', 'author_id', 'activity_id', 'issue_id', 'user_id'
      ] + entity.journalized_options[:format_detail_reflection_columns]
      boolean_columns = [
        'is_private'
      ] + entity.journalized_options[:format_detail_boolean_columns]
      hours_columns = [
        'estimated_hours'
      ] + entity.journalized_options[:format_detail_hours_columns]

      format_entity_journal_detail_method = "format_#{entity.class.name.underscore}_attribute"

      if detail.property == 'attr' && respond_to?(format_entity_journal_detail_method)
        attribute = EasyQueryColumn.new(field)
        # formating from EntityAttributeHelper
        value = send(format_entity_journal_detail_method, entity.class, attribute, detail.value, {:entity => entity, :no_link => true, :no_progress_bar => true})
        old_value = send(format_entity_journal_detail_method, entity.class, attribute, detail.old_value, {:entity => entity, :no_link => true, :no_progress_bar => true})

        # set nil if EntityAttributeHelper not formated value
        value = nil if value == detail.value
        old_value = nil if old_value == detail.old_value
      end
    end
    case detail.property
    when 'attr'
      case detail.prop_key
      when *date_columns
        value ||= begin; detail.value && format_date(detail.value.to_date) rescue nil end
        old_value ||= begin; detail.old_value && format_date(detail.old_value.to_date) rescue nil end
      when *time_columns
        value ||= begin; detail.value && format_time(Time.parse(detail.value), false) rescue nil end
        old_value ||= begin; detail.old_value && format_time(Time.parse(detail.old_value), false) rescue nil end
      when *reflection_columns
        value ||= easy_journal_name_by_reflection(entity, field, detail.value)
        old_value ||= easy_journal_name_by_reflection(entity, field, detail.old_value)
      when *boolean_columns
        value ||= l(detail.value == "0" ? :general_text_No : :general_text_Yes) unless detail.value.blank?
        old_value ||= l(detail.old_value == "0" ? :general_text_No : :general_text_Yes) unless detail.old_value.blank?
      when *hours_columns
        value ||= "%0.02f h" % detail.value.to_f unless detail.value.blank?
        old_value ||= "%0.02f h" % detail.old_value.to_f unless detail.old_value.blank?
      end
      label = l(:field_parent_issue) if detail.prop_key == 'parent_id'
    when 'cf'
      #if they are preloaded(they should be) than this is quicker, but otherwise... :(
      if options[:entity].respond_to?(:custom_field_values)
        cv = options[:entity].custom_field_values.detect{|cfv| cfv.custom_field_id == detail.prop_key.to_i }
        custom_field = cv.custom_field if cv
      end
      custom_field ||= custom_field = detail.custom_field
      if custom_field
        multiple = custom_field.multiple?
        label = custom_field.translated_name
        if detail.value
          cv = CustomFieldValue.new
          cv.custom_field = custom_field
          cv.value = detail.value
          value = format_custom_field_value(cv, :no_html => no_html)
        end
        if detail.old_value
          cv = CustomFieldValue.new
          cv.custom_field = custom_field
          cv.value = detail.old_value
          old_value = format_custom_field_value(cv, :no_html => no_html)
        end
      end
    when 'attachment'
      label = l(:label_attachment)
    when 'relation'
      if detail.value && !detail.old_value
        rel_issue = Issue.visible.find_by_id(detail.value)
        value = rel_issue.nil? ? "#{l(:label_issue)} ##{detail.value}" :
          (no_html ? rel_issue : link_to_issue(rel_issue, :only_path => options[:only_path]))
      elsif detail.old_value && !detail.value
        rel_issue = Issue.visible.find_by_id(detail.old_value)
        old_value = rel_issue.nil? ? "#{l(:label_issue)} ##{detail.old_value}" :
          (no_html ? rel_issue : link_to_issue(rel_issue, :only_path => options[:only_path]))
      end
      label = l(detail.prop_key.to_sym)
    end
    call_hook(:helper_easy_journal_show_detail_after_setting, {:detail => detail, :label => label, :value => value, :old_value => old_value, :options => options })

    # Set default format
    label ||= detail.prop_key
    value ||= detail.value
    old_value ||= detail.old_value

    unless no_html
      label = content_tag(:strong, label)
      if detail.old_value && detail.property != 'relation'
        if !detail.value || detail.value.blank?
          old_value = content_tag(:del, old_value)
        else
          old_value = content_tag(:i, old_value)
        end
      end
      if detail.property == 'attachment'
        # Link to the attachment if it has not been removed
        if !value.blank? && (a = Attachment.where({:id => detail.prop_key, :filename => value}).first || Attachment::Version.where({:id => detail.prop_key, :filename => value}).first)
          if a.is_a?(Attachment) && !a.versions.earliest.nil?
            a = a.versions.earliest
          end
          value = link_to_attachment(a, :download => true, :only_path => only_path)
          if only_path != false && a.is_text?
            value += link_to('',
              {:controller => 'attachments', :action => 'show',
                :id => a, :filename => a.filename, :version => !a.is_a?(Attachment) || nil}, :title => l(:title_show_attachment), :class => 'icon icon-magnifier'
            )
          end
        else
          # if attachment has been deleted...
          value = content_tag(:del, h(value)) if value
        end
      else
        value = content_tag(:i, h(value), :class => 'new-value') if value
      end
    end

    if detail.property == 'attr' && detail.prop_key == 'description'
      s = l(:text_journal_changed_no_detail, :label => label)
      unless no_html
        diff_link = link_to('diff',
          {:controller => 'journals', :action => 'diff', :id => detail.journal_id, :detail_id => detail.id, :only_path => only_path},
          :title => l(:label_view_diff))
        s << " (#{ diff_link })"
      end
      s.html_safe
    elsif !detail.value.blank?
      case detail.property
      when 'attr', 'cf'
        if detail.old_value.present?
          l(:text_journal_changed, :label => label, :old => old_value, :new => value).html_safe
        elsif multiple
          l(:text_journal_added, :label => label, :value => value).html_safe
        else
          l(:text_journal_set_to, :label => label, :value => value).html_safe
        end
      when 'attachment', 'relation'
        l(:text_journal_added, :label => label, :value => value).html_safe
      end
    else
      l(:text_journal_deleted, :label => label, :old => old_value).html_safe
    end
  end

  # Find the name of an associated record stored in the field attribute
  def easy_journal_name_by_reflection(entity, field, id)
    association = entity.class.reflect_on_association(field.to_sym)
    if association
      record = association.class_name.constantize.find_by_id(id)
      if record
        if record.respond_to?(:name)
          return record.name
        else
          return record.to_s
        end
      end
    end
  end

end
IssuesHelper.send(:include, EasyJournalHelper)
