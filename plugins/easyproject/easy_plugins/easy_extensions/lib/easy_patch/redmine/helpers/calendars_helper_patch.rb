module EasyPatch
  module CalendarsHelperPatch

    def self.included(base)
      base.send(:include, InstanceMethods)

      base.class_eval do

        def render_easy_issue_query_form_buttons_bottom_on_issues_calendar(query, options)
          year =  options[:year] || Date.today.year
          month = options[:month] || Date.today.month
          s = '<div id="calendar_listing">'
          s << '<div style="float:left;">'
          s << label_tag('month', l(:label_month))
          s << select_month(month, :prefix => 'month', :discard_type => true)
          s << label_tag('year', l(:label_year))
          s << select_year(year, :prefix => 'year', :discard_type => true)
          s << '</div>'
          s << javascript_tag("$('#calendar_listing select').change(function() {window.location.search = $('#calendar_listing select').serialize()})")
          s << '<div style="float:right;">'
          s << link_to_previous_month(year, month) + ' | ' + link_to_next_month(year, month)
          s << '</p>'
          s << '</div>'
          s.html_safe
        end
      end

    end

    module InstanceMethods
    end

  end
end
EasyExtensions::PatchManager.register_helper_patch 'CalendarsHelper', 'EasyPatch::CalendarsHelperPatch'
