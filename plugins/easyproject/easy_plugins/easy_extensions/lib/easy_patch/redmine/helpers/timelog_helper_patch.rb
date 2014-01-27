module EasyPatch
  module TimelogHelperPatch
    include Redmine::Export::PDF

    def self.included(base)
      base.send(:include, InstanceMethods)

      base.class_eval do

        alias_method_chain :render_timelog_breadcrumb, :easy_extensions

        remove_method :options_for_period_select

        def activity_collection(user=nil,role_id=nil, project=nil)
          project ||= (@new_project || @project)
          user ||= User.current
          if project.nil?
            activities = TimeEntryActivity.shared.active
          else
            if role_id == 'xAll'
              activities = project.activities.active
            else
              activities = project.activities_per_role(user, role_id)
            end
          end

          return activities
        end

        def easy_range_to_string(value)
          time = nil
          if value.is_a?(String)
            begin
              time = value.to_time
            rescue
            end
          elsif value.is_a?(Time) || value.is_a?(DateTime)
            time = value
          end
          if time
            time = value.utc? ? value.localtime : value
            (hour_to_string(time.hour) + ':' + min_to_string(time.min)).html_safe
          end
        end

        def period_label(period)
          case period
          when 'all'
            l(:label_all_time)
          when 'today'
            l(:label_today)
          when 'yesterday'
            l(:label_yesterday)
          when 'current_week'
            l(:label_this_week)
          when 'last_week'
            l(:label_last_week)
          when 'last_2_weeks'
            l(:label_last_n_weeks, 2)
          when '7_days'
            l(:label_last_n_days, 7)
          when 'current_month'
            l(:label_this_month)
          when 'last_month'
            l(:label_last_month)
          when '30_days'
            l(:label_last_n_days, 30)
          when '90_days'
            l(:label_last_n_days, 90)
          when 'current_year'
            l(:label_this_year)
          when 'last_year'
            l(:label_last_year)
          else
            ''
          end
        end

        def render_api_time_entry(api, time_entry)
          api.time_entry do
            api.id(time_entry.id)
            api.project(:id => time_entry.project_id, :name => time_entry.project.name) unless time_entry.project.nil?
            api.issue(:id => time_entry.issue_id) unless time_entry.issue.nil?
            api.user(:id => time_entry.user_id, :name => time_entry.user.name) unless time_entry.user.nil?
            api.activity(:id => time_entry.activity_id, :name => time_entry.activity.name) unless time_entry.activity.nil?
            api.hours(time_entry.hours)
            api.comments(time_entry.comments)
            api.spent_on(time_entry.spent_on)
            api.easy_range_from(time_entry.easy_range_from)
            api.easy_range_to(time_entry.easy_range_to)
            api.easy_external_id(time_entry.easy_external_id)
            api.created_on(time_entry.created_on)
            api.updated_on(time_entry.updated_on)

            render_api_custom_values time_entry.visible_custom_field_values, api
          end
        end

        def hours_selector(time_entry, tag_name_prefix)
          if EasySetting.value('timeentry_hours_selector', time_entry.project) == 'select'
            hours_selector_with_select(time_entry, tag_name_prefix)
          else
            hours_selector_with_textbox(time_entry, tag_name_prefix)
          end
        end

        def hours_selector_with_textbox(time_entry, tag_name_prefix)
          s = ''
          s << label_tag("#{tag_name_prefix}[hours]", l(:field_hours), :class => 'required')
          s << text_field_tag("#{tag_name_prefix}[hours]", time_entry && time_entry.hours , :size => 4, :placeholder => l(:field_hours))

          return content_tag(:p, s.html_safe, :class => 'timeentry-hours splitcontentleft')
        end

        def hours_selector_with_select(time_entry, tag_name_prefix)
          selected_hours, selected_minutes = 0, 0

          if time_entry && time_entry.hours
            hours = time_entry.hours.to_i
            selected_hours = hours.to_s
            selected_minutes = ((time_entry.hours - hours) * 60).to_i.to_s
          end

          s = "<p class='timeentry-hours'>"
          s << hidden_field_tag("#{tag_name_prefix}[hours]", time_entry && time_entry.hours)
          s << label_tag("#{tag_name_prefix}[hours]", l(:field_hours), :class => 'required')
          s << select_tag("#{tag_name_prefix}[hours_hour]", options_for_select(9.times.collect{|h| [h, h.to_s]}, :selected => selected_hours), :class=>'small-fixed-select',
            :onchange => "$('##{convert_form_name_to_id(tag_name_prefix)}_hours').val(parseInt($(this).val()) + (parseInt($('##{convert_form_name_to_id(tag_name_prefix)}_hours_minute').val()) / 60.00))")
          s << '&nbsp;:&nbsp;'
          s << select_tag("#{tag_name_prefix}[hours_minute]", options_for_select([['00', '00'], ['15', '15'], ['30', '30'], ['45', '45']], :selected => selected_minutes), :class=>'small-fixed-select',
            :onchange => "var i =$('##{convert_form_name_to_id(tag_name_prefix)}_hours'); i.val((parseInt(i.val()) + parseFloat(parseInt($(this).val()) / 60.00)))")
          s << '</p>'
          s.html_safe
        end

        def timelog_comment_tag(name, value=nil, options={})
          tag = ''
          if options.delete(:force_text_field) || !EasySetting.value('timelog_comment_editor_enabled')
            tag << text_field_tag(name, value, {:maxlength => 255}.merge(options))
          else
            tag << text_area_tag(name, value, options.merge(:class => 'wiki-edit', :size => '5x3', :id => 'time_entry_comment'))

            tag << wikitoolbar_for('time_entry_comment', {:custom => 'height: 100'}) unless in_mobile_view?
          end

          return tag.html_safe
        end

        def easy_time_entry_query_additional_ending_buttons(time_entry, options = {})
          s = ''
          s << link_to('', {:controller => 'bulk_time_entries', :action => 'index', :time_entry_id => time_entry, :back_url => (params[:back_url] || url_for(params))},
            :title => l(:button_edit), :class => 'icon icon-edit')
          s << link_to('', {:controller => 'timelog', :action => 'destroy', :id => time_entry, :project_id => nil, :back_url => (params[:back_url] || url_for(params))},
            :data => {:confirm => l(:text_are_you_sure)},
            :method => :delete,
            :title => l(:button_delete),
            :class => 'icon icon-del')
          return s.html_safe
        end

      end
    end

    module InstanceMethods

      def render_timelog_breadcrumb_with_easy_extensions
        return unless @project
        return if @only_me

        links = Array.new
        links << link_to(l(:label_project_all), {:project_id => nil, :issue_id => nil})
        @project.self_and_ancestors.collect {|p| links << ((User.current.allowed_to?(:view_time_entries, p, :global => true)) ? link_to(p.name,{:project_id => p, :issue_id => nil}) : p.name)} if @project
        if @issue
          if @issue.visible?
            links << link_to_issue(@issue)
          else
            links << "##{@issue.id}"
          end
        end
        breadcrumb links
      end
    end
  end
end
EasyExtensions::PatchManager.register_helper_patch 'TimelogHelper', 'EasyPatch::TimelogHelperPatch'
