module EasyPatch
  module IssuesHelperPatch

    def self.included(base)
      base.send(:include, InstanceMethods)

      base.class_eval do

        alias_method_chain :details_to_strings, :easy_extensions
        alias_method_chain :issue_list, :easy_extensions
        alias_method_chain :render_descendants_tree, :easy_extensions
        alias_method_chain :render_issue_tooltip, :easy_extensions
        alias_method_chain :show_detail, :easy_extensions

        def newform_assignable_users_collection(issue, project)
          assignable_users = issue.assignable_users
          assignable_users_for_options = []
          if assignable_users.include?(User.current)
            assignable_users_for_options << ["<< #{l(:label_me)} >>".html_safe, User.current.id]
          end
          assignable_users_for_options.concat(assignable_users.collect{|m| [m.name, m.id]})
          users_and_groups = [
            [l(:label_issue_assigned_to_users), assignable_users_for_options],
            [l(:label_issue_assigned_to_groups), issue.assignable_groups.collect{|m| [m.name, m.id]}],
          ] if project
          users_and_groups ||= []
          users_and_groups
        end

        def newform_assignable_users_options(issue, project)
          project ||= issue.project
          grouped_options_for_select(newform_assignable_users_collection(issue, project), issue.assigned_to_id, (issue.assigned_to_id.blank? ? '' : nil))
        end

        def assigned_to_collection_for_select_options(issue)
          options = []
          if issue
            assignable_users = issue.assignable_users
            options << ["<< #{l(:label_me)} >>".html_safe, User.current.id] if assignable_users.include?(User.current)
            options << [l(:label_author_assigned_to), issue.author_id] if issue.author && issue.assigned_to_id != issue.author_id
            options << [l(:label_last_user_assigned_to), issue.last_user_assigned_to.id] if issue.last_user_assigned_to && issue.assigned_to_id != issue.last_user_assigned_to.id
            issue.assignable_users.each{|au| options << [au.name, au.id]}
          end
          options
        end

        def options_for_issues(issues, selected, user=nil)
          user ||= User.current

          html = '<option></option>'
          html << options_from_collection_for_select(issues, :id, :to_s, selected)
          html
        end

        def return_issues_members_for_restrictions_users
          members = @issue.assignable_users.sort_by(&:name)
          members << @issue.assignable_groups
          members.flatten!
          members.map! {|a| [a.name, a.id]}
          members.insert(0, [l(:select_option_issue_restrictions_users_blank),nil])
          return members
        end

        def issues_relations_field_tag(field_name, field_id, values = [], options = {})
          selected_values = EasyExtensions::CustomFields::EasyLookupCustomFieldFormat.entity_ids_to_lookup_values('Issue', values, :display_name => :subject)
          easy_modal_selector_field_tag('Issue', 'link_with_subject', field_name, field_id, selected_values, options)
        end

        def render_ancestors_tree(issue)
          s = '<form action=""><table class="list issues">'
          issue_list(issue.ancestors.sort_by(&:lft)) do |child, level|
            s << content_tag('tr',
              content_tag('td', check_box_tag("ids[]", child.id, false, :id => nil), :class => 'checkbox') +
                content_tag('td', link_to_issue(child, :truncate => 60), :class => 'subject') +
                content_tag('td', h(child.status), :class => 'status') +
                content_tag('td', link_to_user(child.assigned_to), :class => 'assigned_to') +
                content_tag('td', progress_bar(child.done_ratio, :width => '80px'), :class => 'done_ratio') +
                content_tag('td', easy_issue_query_additional_ending_buttons(child)),
              :class => "#{child.css_classes} issue-#{child.id} hascontextmenu ", :onclick => "javascript:GoToURL('#{url_for({:controller => 'issues', :action => 'show', :id => child})}', event)")
          end
          s << '</table></form>'
          s.html_safe
        end

        def easy_issue_query_additional_ending_buttons(issue, options = {})
          s = ''
          s << issue_last_journal_link(issue, options) unless in_mobile_view?
          s << link_to('',{:controller => 'issues', :action => 'edit', :id => issue}, :class => 'icon icon-edit xl-icon', :title => l(:button_update))

          return s.html_safe
        end

        def issue_last_journal_link(issue, options)
          link_to('', {:controller => 'easy_issues', :action => 'render_last_journal', :id => issue, :block_name => options[:block_name], :uniq_id => options[:uniq_id] }, :id => "#{options[:block_name]}#{options[:uniq_id]}link-to-easy-issues-render-last-journal-#{issue.id}", :remote => true, :title => l(:title_last_journal_link), :class => 'icon icon-issue-update xl-icon')
        end

        def render_visible_issue_attributes_for_edit(issue, form, options={})
          s = '<div class="splitcontentleft">'
          s << (render_visible_issue_attribute_for_edit_assigned_to_id(issue, form, options) || '')
          s << (render_visible_issue_attribute_for_edit_status_id(issue, form, options) || '')
          s << (render_visible_issue_attribute_for_edit_restrictions_users(issue, form, options) || '')
          s << (render_visible_issue_attribute_for_edit_done_ratio(issue, form, options) || '')

          s << (call_hook(:helper_issues_render_visible_issue_attribute_for_edit_bottom_left, {:issue => issue, :form => form, :options => options}) || '')

          s << '</div>'
          s << '<div class="splitcontentright">'
          s << (render_visible_issue_attribute_for_edit_priority_id(issue, form, options) || '')
          unless issue.tracker.easy_is_meeting?
            s << (render_visible_issue_attribute_for_edit_due_date(issue, form, options) || '')
          else
            s << (render_visible_issue_attribute_for_edit_meeting_datetime(issue, form, options) || '')
          end

          s << (call_hook(:helper_issues_render_visible_issue_attribute_for_edit_bottom_right, {:issue => issue, :form => form, :options => options}) || '')

          s << '</div>'
          s << '<div>'
          s << '</div>'
          s << '<div id="visible-custom-fields" style="clear:both">'
          s << render(:partial => 'issues/edit_form_updatable_attributes', :locals => {:show_on_more_form => false})
          s << '</div>'
          s.html_safe
        end

        def render_hidden_issue_attributes_for_edit(issue, form, options={})
          s = '<div class="splitcontentleft">'
          s << (render_hidden_issue_attribute_for_edit_tracker_id(issue, form, options) || '')
          s << (render_hidden_issue_attribute_for_edit_author_id(issue, form, options) || '')
          s << (render_hidden_issue_attribute_for_edit_category_id(issue, form, options) || '')
          s << (render_hidden_issue_attribute_for_edit_fixed_version_id(issue, form, options) || '')

          s << (call_hook(:helper_issues_render_hidden_issue_attribute_for_edit_bottom_left, {:issue => issue, :form => form, :options => options}) || '')

          s << '</div>'
          s << '<div class="splitcontentright">'
          unless issue.tracker.easy_is_meeting?
            s << (render_hidden_issue_attribute_for_edit_start_date(issue, form, options) || '')
          end
          s << (render_hidden_issue_attribute_for_edit_estimated_hours(issue, form, options) || '')
          s << (render_hidden_issue_attribute_for_edit_is_private(issue, form, options) || '')

          s << (call_hook(:helper_issues_render_hidden_issue_attribute_for_edit_bottom_right, {:issue => issue, :form => form, :options => options}) || '')

          s << '</div>'
          s.html_safe
        end

        def render_visible_issue_attribute_for_edit_assigned_to_id(issue, form, options={})
          return if issue.disabled_core_fields.include?('assigned_to_id') || !issue.safe_attribute?('assigned_to_id')
          issue_ajax_url = options[:issue_ajax_url]
          issue_ajax_url ||= url_for({ :controller => 'issues', :action => :update_form, :project_id => issue.project, :id => issue, :format => 'js' })
          content_tag(:p,
            form.select(:assigned_to_id, assigned_to_collection_for_select_options(issue), :include_blank => true),
            :onchange => "$.ajax({url: '#{j issue_ajax_url}', type: 'post', data: $('#issue-form').serialize()});",
            :class => 'assigned-to-id')
        end

        def render_visible_issue_attribute_for_edit_status_id(issue, form, options={})
          return unless issue.safe_attribute?('status_id')
          content_tag(:p,
            form.select(:status_id, (@allowed_statuses.collect {|p| [p.name, p.id]}), {:required => true}, {}),
            :class => 'status-id') if @allowed_statuses.any?
        end

        def render_visible_issue_attribute_for_edit_restrictions_users(issue, form, options={})
          content_tag(:p,
            label_tag('restrictions_users', l(:label_restrictions_users)) +
              select_tag('restrictions_users[]', options_for_select(return_issues_members_for_restrictions_users), :id => 'restrictions_users') +
              link_to_function('', 'ToggleMultiSelect(\'restrictions_users\', \'\');', :class => 'toggle-bullet textcon-plus'),
            :class => 'restrictions-users') if User.current.allowed_to?(:view_restrictions_users, issue.project) && EasySetting.value('edit_issue_columns_list', issue.project).include?('restrictions_users')
        end

        def render_visible_issue_attribute_for_edit_priority_id(issue, form, options={})
          return unless issue.safe_attribute?('priority_id')
          content_tag(:p,
            form.select(:priority_id, (@priorities.collect {|p| [p.name, p.id]}), {:required => true}, {:disabled => !@edit_allowed}),
            :class => 'priority-id')
        end

        def render_visible_issue_attribute_for_edit_due_date(issue, form, options={})
          return if issue.disabled_core_fields.include?('due_date') || !issue.safe_attribute?('due_date')
          content_tag(:p,
            form.text_field(:due_date, :size => 10, :disabled => !@edit_allowed) +
              ((calendar_for('issue_due_date') if @edit_allowed) || ''),
            :class => 'due-date')
        end

        def render_visible_issue_attribute_for_edit_meeting_datetime(issue, form, options={})
          res = ''
          res << content_tag(:p,
            form.text_field(:start_date, :size => 10, :disabled => !issue.leaf?, :required => true, :tabindex => 110) +
              ((calendar_for('issue_start_date') if issue.leaf?) || '') +
              content_tag( :span, select_time( issue.author.user_time_in_zone(issue.easy_start_date_time || Time.now), {:minute_step => 5, :ignore_date => true, :prefix => 'issue[easy_start_date_time]'}, :disabled => !@edit_allowed ), :class => 'meeting_times' ),
            :class => 'nowrap')
          res << content_tag(:p,
            form.text_field(:due_date, :size => 10, :disabled => !@edit_allowed) +
              ((calendar_for('issue_due_date') if @edit_allowed) || '') +
              content_tag( :span, select_time( issue.author.user_time_in_zone(issue.easy_due_date_time || Time.now), {:minute_step => 5, :ignore_date => true, :prefix => 'issue[easy_due_date_time]'}, :disabled => !@edit_allowed ), :class => 'meeting_times' ),
            :class => 'due-date')
          date_js = 'var due_date_id = "issue_due_date";
                  var start_date_id = "issue_start_date";
                  if ( $("#"+due_date_id).val() == "" ) {
                    $("#"+due_date_id).val($("#"+start_date_id).val());
                  }
                  var user_changed_due_date = ($("#"+due_date_id).val() != $("#"+start_date_id).val());
                  $("#"+start_date_id).change(function(){
                    if ( !user_changed_due_date ) {
                      $("#"+due_date_id).val($("#"+start_date_id).val());
                    }
                  });
                  $("#"+due_date_id).change(function(){
                    user_changed_due_date = true;
                  });'
          res << javascript_tag(date_js)
          res.html_safe
        end

        def render_visible_issue_attribute_for_edit_done_ratio(issue, form, options={})
          return if issue.disabled_core_fields.include?('done_ratio') || !issue.safe_attribute?('done_ratio')
          content_tag(:p,
            form.select(:done_ratio, ((0..10).to_a.collect{|r| ["#{r*10} %", r*10]})),
            :class => 'done-ratio')
        end

        def render_hidden_issue_attribute_for_edit_tracker_id(issue, form, options={})
          if @project && @project.trackers.count > 1
            if issue.safe_attribute? 'tracker_id'
              content_tag(:p,
                form.select(:tracker_id, @project.trackers.collect {|t| [t.name, t.id]}, {:required => true}, {:tabindex => 40,
                    :onchange => "$.ajax({url: '#{j options[:issue_ajax_url]}', type: 'post', data: $('#issue-form').serialize()});"})
              )
            end
          else
            form.hidden_field(:tracker_id, :value => issue.tracker_id)
          end
        end

        def render_hidden_issue_attribute_for_edit_author_id(issue, form, options={})
          return unless issue.safe_attribute?('author_id')
          content_tag(:p,
            form.select(:author_id, options_from_collection_for_select(issue.project.users.active.non_system_flag.sorted.push(issue.author).uniq, 'id', 'name', issue.author_id))
          )
        end

        def render_hidden_issue_attribute_for_edit_category_id(issue, form, options={})
          return unless issue.safe_attribute?('category_id') && @project.issue_categories.any?
          content_tag(:p,
            form.select(:category_id, (issue_category_tree_options_for_select(@project.issue_categories, :selected => issue.category_id)), {:include_blank => true, :required => issue.required_attribute?('category_id')}, {})
          )
        end

        def render_hidden_issue_attribute_for_edit_fixed_version_id(issue, form, options={})
          return unless issue.safe_attribute?('fixed_version_id') && issue.assignable_versions.any?
          content_tag(:p,
            form.select(:fixed_version_id, version_options_for_select(issue.assignable_versions, issue.fixed_version), {:include_blank => true, :required => issue.required_attribute?('fixed_version_id')}, {:tabindex => 90,
                :onchange => "$.ajax({url: '#{j options[:issue_ajax_url]}', type: 'post', data: $('#issue-form').serialize()});"}) +
              hidden_field_tag('issue[old_fixed_version_id]', issue.fixed_version_id, :id => 'issue_old_fixed_version_id')
          )
        end

        def render_hidden_issue_attribute_for_edit_start_date(issue, form, options={})
          return unless issue.safe_attribute?('start_date')
          content_tag(:p,
            form.text_field(:start_date, :size => 10, :disabled => !issue.leaf?, :required => issue.required_attribute?('start_date'), :tabindex => 110) +
              ((calendar_for('issue_start_date') if issue.leaf?) || '').html_safe,
            :class => 'nowrap')
        end

        def render_hidden_issue_attribute_for_edit_estimated_hours(issue, form, options={})
          return unless @project.module_enabled?(:time_tracking) && issue.safe_attribute?('estimated_hours') && User.current.allowed_to?(:view_estimated_hours, @project)
          content_tag(:p,
            form.text_field(:estimated_hours, :size => 3, :required => issue.required_attribute?('estimated_hours'), :tabindex => 130) +
              content_tag(:span, l(:field_hours))
          )
        end

        def render_hidden_issue_attribute_for_edit_is_private(issue, form, options={})
          return unless EasySetting.value('enable_private_issues') && issue.safe_attribute_names.include?('is_private')
          content_tag(:p,
            label_tag('issue_is_private', l(:field_is_private)) + form.check_box(:is_private, :no_label => true)
          )
        end

        def render_show_issue_custom_fields(custom_field_values, layout = :two_columns, options = {})
          render_method = "render_show_issue_custom_fields_#{layout}"
          if respond_to?(render_method)
            return content_tag(:div, send(render_method, custom_field_values, options).html_safe, :class => "issue-custom-filed-values #{layout}")
          else
            return l(:notice_render_show_cf_values_mehod_not_found)
          end
        end

        def content_tag_for_issue_custom_field_value(value, options= {})
          return content_tag(:div, "#{content_tag(:span, h(value.custom_field.translated_name) + ':')} #{show_value(value)}".html_safe, :class => 'view-issue-custom-field' )
        end

        def render_show_issue_custom_fields_one_column(custom_field_values, options = {})
          cfs = ''
          custom_field_values.each do |value|
            cfs << content_tag_for_issue_custom_field_value(value)
          end

          return cfs.html_safe
        end

        def render_show_issue_custom_fields_two_columns(custom_field_values, options = {})
          left = ''; right = ''
          custom_field_values.each_with_index do |value, i|
            item = content_tag_for_issue_custom_field_value(value)
            if i.even?
              left << item
            else
              right << item
            end
          end

          return content_tag(:div, left.html_safe, :class => 'splitcontentleft') + content_tag(:div, right.html_safe, :class => 'splitcontentright') + content_tag(:div, '', :class => 'clear')
        end

        def easy_issue_timer_button(issue, user=User.current)
          return unless EasyIssueTimer.active?(issue.project)
          timer = issue.easy_issue_timers.where(:user_id => user.id).running.last
          if timer && !timer.paused?
            links = ''
            links << content_tag(:span, link_to(l(:button_easy_issue_timer_stop), easy_issue_timer_stop_path(issue, :timer_id => timer), :class => 'button-2 icon icon-checked-circle', :method => :post, :title => l(:title_easy_issue_timer_button_stop), :onclick => "$(this).css({'z-index': -1})"), :class => 'splitcontentleft')
            links << content_tag(:span, link_to(l(:button_easy_issue_timer_pause), easy_issue_timer_pause_path(issue, :timer_id => timer), :class => ' button-2 icon icon-pause', :method => :post, :title => l(:title_easy_issue_timer_button_pause), :onclick => "$(this).css({'z-index': -1})"), :class => 'splitcontentright')
            content_tag(:div, links.html_safe, :class => 'easy-issue-timers-stop-n-pause-buttons splitcontent')
          else
            link_to(l((timer.nil? ? :button_easy_issue_timer_play : :button_easy_issue_timer_resume)), easy_issue_timer_play_path(issue, :timer_id => timer), :class => 'button-2 icon icon-play', :method => :post, :title => l(:title_easy_issue_timer_button_play), :onclick => "$(this).css({'z-index': -1})")
          end
        end

        def heading_issue(issue)
          content_tag(:h2, h(issue), :class => 'issue-detail-header', :data => {:entity_type => 'Issue', :entity_id => issue.id, :handler => true})
        end

        def issue_category_tree_with_level_and_name_prefix(issue_categories)
          IssueCategory.each_with_level(issue_categories) do |category, level|
            next if category.nil? || category.id.nil?

            name_prefix = (level > 0 ? '|&nbsp;&nbsp;' * level + '&#8627; ' : '')
            if name_prefix.length > 0
              name_prefix = name_prefix.slice(1, name_prefix.length)
            end

            yield(category, level, name_prefix.html_safe)
          end
        end

        def issue_category_tree_options_for_select(issue_categories, options={})
          s = ''
          issue_category_tree(issue_categories) do |category, level|
            if category.nil? || category.id.nil?
              next
            end

            name_prefix = (level > 0 ? '|&nbsp;&nbsp;' * level + '&#8627; ' : '')
            if name_prefix.length > 0
              name_prefix = name_prefix.slice(1, name_prefix.length)
            end
            name_prefix = name_prefix.html_safe
            tag_options = { :value => category.id }
            if !options[:selected].nil? && category.id == options[:selected]
              tag_options[:selected] = 'selected'
            else
              tag_options[:selected] = nil
            end

            if !options[:current].nil? && options[:current].id == category.id
              tag_options[:disabled] = 'disabled'
            end

            tag_options.merge!(yield(category)) if block_given?
            s << content_tag('option', name_prefix + h(category), tag_options)
          end
          s.html_safe
        end

        def issue_category_tree(issue_categories, &block)
          IssueCategory.each_with_level(issue_categories, &block)
        end

        def render_issue_category_with_tree(category)
          s = ''
          if category.nil?
            return ''
          end
          ancestors = category.root? ? [] : category.ancestors.all
          if ancestors.any?
            s << '<ul id="issue_category_tree">'
            ancestors.each do |ancestor|
              s << '<li>' + content_tag('span', h(ancestor.name)) + "<ul #{"class='first-child'" if ancestor.root?}>"
            end
            s << '<li>'
          end

          s << content_tag('span', h(category.name), :class => 'issue_category')

          if ancestors.any?
            s << '</li></ul>' * (ancestors.size + 1)
          end
          s.html_safe
        end

        def render_issue_category_with_tree_inline(category)
          s = ''
          if category.nil?
            return ''
          end
          ancestors = category.root? ? [] : category.ancestors.all
          if ancestors.any?
            ancestors.each do |ancestor|
              s << content_tag('span', h(ancestor.name), :class => 'parent')
            end
          end

          s << content_tag('span', h(category.name), :class => 'issue_category')

          if ancestors.any?
            s = content_tag('span', s, { :class => 'issue_category_tree' }, false)
          end
          s.html_safe
        end

        def move_category_path(category, direction)
          url_for({ :controller => 'issue_categories', :action => 'move_category', :id => category.id, :direction => direction })
        end

      end
    end

    module InstanceMethods

      def issue_list_with_easy_extensions(issues, &block)
        Issue.each_with_easy_level(issues) do |issue, level|
          yield issue, level
        end
      end

      # options:
      # => :no_html = true/false (default je false)
      # => :only_path = true/false (default je true)
      def show_detail_with_easy_extensions(detail, no_html=false, options={})
        show_easy_journal_detail(detail, no_html, options)
      end
      def details_to_strings_with_easy_extensions(details, no_html=false, options={})
        easy_journal_details_to_strings(details, no_html, options)
      end

      def render_descendants_tree_with_easy_extensions(issue)
        s = '<form action=""><table class="list issues">'
        issue_list(issue.descendants.visible.sort_by(&:lft)) do |child, level|
          css = "issue issue-#{child.id} hascontextmenu"
          css << " idnt idnt-#{level}" if level > 0
          s << content_tag('tr',
            content_tag('td', check_box_tag("ids[]", child.id, false, :id => nil), :class => 'checkbox') +
              content_tag('td', link_to_issue(child, :truncate => 60, :project => (issue.project_id != child.project_id)), :class => 'subject') +
              content_tag('td', h(child.status), :class => 'status') +
              content_tag('td', link_to_user(child.assigned_to), :class => 'assigned_to') +
              content_tag('td', progress_bar(child.done_ratio, :width => '80px'), :class => 'done_ratio') +
              content_tag('td', easy_issue_query_additional_ending_buttons(child)) +
              content_tag('td', link_to('', {:controller => 'easy_issues', :action => 'remove_child', :id => issue, :child_id => child}, :method => :delete, :remote => true, :data => {:confirm => l(:text_are_you_sure)}, :class => 'icon icon-del', :title => l(:title_issue_remove_parent)) ),
            :id => "issue-descendants-tree-child-#{child.id}",
            :class => "#{child.css_classes} issue-#{child.id} hascontextmenu #{level > 0 ? "idnt idnt-#{level}" : nil}",
            :onclick => "javascript:GoToURL('#{url_for({:controller => 'issues', :action => 'show', :id => child})}', event)")
        end
        s << '</table></form>'
        s.html_safe
      end

      def render_issue_tooltip_with_easy_extensions(issue)
        res = render_issue_tooltip_without_easy_extensions( issue )
        meeting_time = format_issue_meeting_time(issue)
        if meeting_time
          @cached_label_meeting_time ||= l(:field_easy_meeting_time)
          res + "<br /><strong>#{@cached_label_meeting_time}</strong>: #{meeting_time}".html_safe
        else
          res
        end
      end
    end

  end

  module IssueFieldsRowsPatch
    def self.included(base)
      base.send(:include, InstanceMethods)
      base.class_eval do
        alias_method_chain :cells, :easy_extensions
      end
    end

    module InstanceMethods
      def cells_with_easy_extensions(label, text, options={})
        text_options = options.delete(:text_options) || {}
        content_tag('th', "#{label}:", options) + content_tag('td', content_tag('span', text, text_options), options)
      end
    end
  end
end
EasyExtensions::PatchManager.register_helper_patch 'IssuesHelper', 'EasyPatch::IssuesHelperPatch'
EasyExtensions::PatchManager.register_helper_patch 'IssuesHelper::IssueFieldsRows', 'EasyPatch::IssueFieldsRowsPatch'
