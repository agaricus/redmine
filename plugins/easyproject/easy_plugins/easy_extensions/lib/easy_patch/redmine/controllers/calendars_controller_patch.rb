module EasyPatch
  module CalendarsControllerPatch

    def self.included(base)
      base.send(:include, InstanceMethods)

      base.class_eval do

        helper :entity_attribute
        include EntityAttributeHelper
        helper :easy_query
        include EasyQueryHelper

        alias_method_chain :show, :easy_extensions

      end
    end

    module InstanceMethods

      def show_with_easy_extensions
        if params[:year] and params[:year].to_i > 1900
          @year = params[:year].to_i
          if params[:month] and params[:month].to_i > 0 and params[:month].to_i < 13
            @month = params[:month].to_i
          end
        end
        @year ||= Date.today.year
        @month ||= Date.today.month

        @calendar = Redmine::Helpers::Calendar.new(Date.civil(@year, @month, 1), current_language, :month)

        retrieve_query(EasyIssueQuery)

        @query.display_filter_fullscreen_button = false
        @query.display_save_button = false
        @query.display_filter_columns_on_index, @query.display_filter_group_by_on_index, @query.display_filter_sort_on_index = false, false, false
        @query.export_formats = {}

        @query.group_by = nil
        if @query.valid?
          events = []
          events += @query.entities(:conditions => ["((#{Issue.table_name}.start_date BETWEEN ? AND ?) OR (#{Issue.table_name}.due_date BETWEEN ? AND ?))", @calendar.startdt, @calendar.enddt, @calendar.startdt, @calendar.enddt])
          if @project
            events += @project.shared_versions.where(["#{Version.table_name}.effective_date BETWEEN ? AND ?", @calendar.startdt, @calendar.enddt]).all
          else
            events += @query.versions(:conditions => ["#{Version.table_name}.effective_date BETWEEN ? AND ?", @calendar.startdt, @calendar.enddt])
          end

          @calendar.events = events
        end

        render :action => 'show', :layout => false if request.xhr?
      end

    end
  end
end
EasyExtensions::PatchManager.register_controller_patch 'CalendarsController', 'EasyPatch::CalendarsControllerPatch'
