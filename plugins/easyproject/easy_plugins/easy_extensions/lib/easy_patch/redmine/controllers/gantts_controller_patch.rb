module EasyPatch
  module GanttsControllerPatch

    def self.included(base)
      base.send(:include, InstanceMethods)

      base.class_eval do
        helper :easy_query
        include EasyQueryHelper
        helper :entity_attribute
        include EntityAttributeHelper
        helper :custom_fields

        alias_method_chain :show, :easy_extensions
        alias_method_chain :find_optional_project, :easy_extensions

        skip_before_filter :find_project, :only => [:update_issues]

        def render_to_fullscreen
          retrieve_query(EasyIssueQuery)
          @query.group_by = nil
          @query.display_filter_sort_on_index, @query.display_filter_columns_on_index, @query.display_filter_group_by_on_index = false, false, false
          @query.export_formats = {}

          additional_statement = "#{Issue.table_name}.start_date IS NOT NULL"

          if @query.additional_statement.blank?
            @query.additional_statement = additional_statement
          else
            @query.additional_statement << ' AND ' + additional_statement
          end

          @zoom = if params[:zoom].present?
            params[:zoom]
          else
            (@query.settings && @query.settings['zoom']) || 'week'
          end

          @grouped_issues = @query.issues_with_versions(:limit => Setting.gantt_items_limit.blank? ? nil : Setting.gantt_items_limit.to_i, :order => "#{Issue.table_name}.start_date ASC")
          render :partial => 'super_gantt', :locals => {:element_id => 'easygantt-container-fs'}
        end

        def update_issues
          errors = []
          if params[:items]
            errors = update_items(params[:items], true)
          end
          render :json => {:type => errors.any? ? 'error' : 'notice', :html => errors.any? ? errors.join('<br/>') : l(:notice_successful_update)}
        end

        def validate_issue
          issue = Issue.find(params[:issue_id])
          issue.due_date = params['end']
          issue.start_date = params['start']
          if issue.valid?
            render_api_ok
          else
            render :json => {:type => 'error', :html => issue.errors.full_messages.join('<br/>')}
          end
        end

        def projects
          retrieve_query(EasyProjectQuery)
          @query.settings = params[:easy_query][:settings] if params[:easy_query]
          @query.display_filter_fullscreen_button = false
          @query.display_filter_sort_on_index, @query.display_filter_columns_on_index, @query.display_filter_group_by_on_index = false, false, false
          @query.export_formats = {}

          additional_statement = "#{Project.table_name}.easy_is_easy_template=#{@query.connection.quoted_false}"
          unless EasySetting.value('project_calculate_start_date')
            additional_statement << " AND #{Project.table_name}.easy_start_date IS NOT NULL"
          end
          unless EasySetting.value('project_calculate_due_date')
            additional_statement << " AND #{Project.table_name}.easy_due_date IS NOT NULL"
          end

          get_zoom

          if @query.additional_statement.blank?
            @query.additional_statement = additional_statement
          else
            @query.additional_statement << ' AND ' + additional_statement
          end

          respond_to do |format|
            format.html
            format.api {
              @projects = @query.entities(:limit => Setting.gantt_items_limit.blank? ? nil : Setting.gantt_items_limit.to_i, :order => "#{Project.table_name}.lft ASC").delete_if {|p| p.start_date.blank? || p.due_date.blank?}
              add_non_filtered_projects if @projects.any?
            }
          end
        end

        private

        def update_items(items, save=false)
          errors = []

          items.each do |k, item|

            if item['type'] == 'issue'
              issue = Issue.find(item['id'].to_i)
              if issue
                issue.init_journal(User.current)
                issue.due_date = item['end']
                issue.start_date = item['start']
                if save
                  saved = true
                  begin
                    saved = issue.save
                  rescue ActiveRecord::StaleObjectError
                    issue.reload
                    issue.init_journal(User.current)
                    issue.due_date = item['end']
                    issue.start_date = item['start']
                    saved = issue.save
                  end
                  unless saved
                    errors << l(:notice_failed_to_save_issues2, :issue => '"' + issue.subject + '"', :error =>  issue.errors.full_messages.first)
                  end
                elsif !issue.valid?
                  errors << l(:notice_failed_to_save_issues2, :issue => '"' + issue.subject + '"', :error =>  issue.errors.full_messages.first)
                end
              end
            end

            if item['type'] == 'milestone'
              version = Version.find(item['id'].to_i)
              if version
                version.effective_date = item['date']
                version.save
              end
            end

            if item['type'] == 'project'
              project = Project.find(item['id'].to_i)
              if project
                project.start_date = item['start']
                project.due_date = item['end']
                project.save
              end
            end

          end

          errors
        end

        def add_non_filtered_projects
          ancestors = []
          ancestor_conditions = @projects.collect{|project| "(#{Project.left_column_name} < #{project.left} AND #{Project.right_column_name} > #{project.right})"}
          if ancestor_conditions.any?
            ancestor_conditions = "(#{ancestor_conditions.join(' OR ')})  AND (#{Project.table_name}.id NOT IN (#{@projects.collect(&:id).join(',')}))"
            ancestors = Project.find(:all, :conditions => ancestor_conditions)
          end

          ancestors.each do |p|
            p.nofilter = 'nofilter'
          end

          @projects << ancestors
          @projects = @projects.flatten.uniq.sort_by(&:lft)
        end


        def get_zoom
          if params[:zoom].present? && !request.xhr?
            @zoom = params[:zoom]
            unless @query.new_record?
              @query.settings ||=  {}
              @query.settings['zoom'] = @zoom
              @query.save
            end
          else
            @zoom = (@query.settings && @query.settings['zoom']) || 'week'
          end
        end

        def set_versions_setting
          if @query && @query.project && !request.xhr?
            show_all_versions, versions_above = false, false
            if @query.settings.is_a?(Hash)
              show_all_versions = true if @query.settings.has_key?('gantt_show_all_versions')
              versions_above    = true if @query.settings.has_key?('gantt_versions_above')
            end
            s = EasySetting.where(:name => 'gantt_show_all_versions', :project_id => @query.project.id).first || EasySetting.new(:name => 'gantt_show_all_versions', :project_id => @query.project.id)
            s.value = show_all_versions
            s.save
            s = EasySetting.where(:name => 'gantt_versions_above', :project_id => @query.project.id).first || EasySetting.new(:name => 'gantt_versions_above', :project_id => @query.project.id)
            s.value = versions_above
            s.save
          end
        end
      end
    end

    module InstanceMethods

      def show_with_easy_extensions
        retrieve_query(EasyIssueQuery)
        @query.settings ||= {}
        @query.settings.merge! params[:easy_query][:settings] if params[:easy_query] && params[:easy_query][:settings].is_a?(Hash)
        @query.display_filter_fullscreen_button = false
        @query.display_filter_sort_on_index, @query.display_filter_columns_on_index, @query.display_filter_group_by_on_index = false, true, true
        @query.export_formats.delete_if{|k| ![:msp].include?(k)}

        get_zoom
        set_versions_setting

        first_issue = @query.entities(:limit => 1, :order => "#{Issue.table_name}.start_date ASC", :conditions => "#{Issue.table_name}.start_date IS NOT NULL").try(:first)
        if first_issue
          @start_date = first_issue.start_date
        else
          first_due_issue = @query.entities(:limit => 1, :order => "#{Issue.table_name}.due_date ASC", :conditions => "#{Issue.table_name}.due_date IS NOT NULL").try(:first)
          if first_due_issue
            @start_date = first_due_issue.due_date - 1.day
          else
            @start_date = Date.today
          end
        end

        if params[:format] != 'html'
          @grouped_issues = @query.issues_with_versions(:limit => Setting.gantt_items_limit.blank? ? nil : Setting.gantt_items_limit.to_i,
            :order => "COALESCE(#{Issue.table_name}.due_date, (#{Issue.table_name}.start_date + INTERVAL '1' DAY)) ASC", :include => [:relations_to, :time_entries])
        end

        respond_to do |format|
          format.html { render :action => 'show', :layout => !request.xhr? }
          format.pdf  {
            theme = EasyGanttTheme.find_by_id(params[:easy_gantt_theme_id]) if params[:easy_gantt_theme_id]
            gantt = EasyExtensions::PdfGantt.new(:project => @project, :entities => @grouped_issues, :zoom => @zoom, :query => @query, :theme => theme, :format => params[:pdf_format] || 'A4')
            send_data(gantt.output(@start_date || Date.today), :type => 'application/pdf',
              :disposition => 'inline',
              :filename => "#{(@project ? "#{@project.identifier}-" : '') + 'gantt'}.pdf")
          }
          format.api
        end
      end

      def find_optional_project_with_easy_extensions
        #easy query workaround
        return if params[:project_id] && params[:project_id].match(/\A(=|\!|\!\*|\*)\S*/)
        find_optional_project_without_easy_extensions
      end

    end

  end
end
EasyExtensions::PatchManager.register_controller_patch 'GanttsController', 'EasyPatch::GanttsControllerPatch'
