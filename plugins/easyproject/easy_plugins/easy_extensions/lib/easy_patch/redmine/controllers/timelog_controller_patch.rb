require 'utils/dateutils'

module EasyPatch
  module TimelogControllerPatch

    def self.included(base)
      base.send(:include, InstanceMethods)

      base.class_eval do

        menu_item :spent_time

        before_filter :find_project_for_new_time_entry, :only => [:create]
        before_filter :find_time_entry, :only => [:show, :edit, :update]
        before_filter :find_time_entries, :only => [:bulk_edit, :bulk_update, :destroy, :change_issues_for_bulk_edit]
        before_filter :authorize, :except => [:new, :index, :report, :user_spent_time, :change_role_activities, :change_projects_for_bulk_edit, :change_issues_for_bulk_edit, :change_issues_for_timelog]

        before_filter :find_optional_project, :only => [:index, :report]
        before_filter :find_optional_project_for_new_time_entry, :only => [:new]
        before_filter :authorize_global, :only => [:new, :index, :report]

        before_render :time_entries_clear_activities, :only => [:bulk_edit]
        before_filter :load_allowed_projects_for_bulk_edit #, :only => [:bulk_edit, :change_issues_for_bulk_edit, :change_issues_for_timelog, :new, :create, :edit]
        before_render :load_allowed_issues_for_bulk_edit, :only => [:bulk_edit, :edit, :new, :create, :update]
        before_render :set_selected_visible_issue

        helper :bulk_time_entries
        include BulkTimeEntriesHelper
        helper :easy_query
        include EasyQueryHelper
        helper :entity_attribute
        include EntityAttributeHelper
        helper :custom_fields
        include CustomFieldsHelper
        helper :sort
        include SortHelper

        include EasyUtils::DateUtils

        alias_method_chain :bulk_update, :easy_extensions
        alias_method_chain :create, :easy_extensions
        alias_method_chain :find_optional_project, :easy_extensions
        alias_method_chain :index, :easy_extensions
        alias_method_chain :set_flash_from_bulk_time_entry_save, :easy_extensions
        alias_method_chain :new, :easy_extensions
        alias_method_chain :report, :easy_extensions
        alias_method_chain :time_entry_scope, :easy_extensions

        def user_spent_time
          spent_on = []
          spent_on += params[:time_entries].collect{|k, v| v[:spent_on]} if !params[:time_entries].nil?
          spent_on += params[:saved_time_entries].collect{|k, v| v[:spent_on]} if !params[:saved_time_entries].nil?
          spent_on += [params[:spent_on]] if !params[:spent_on].nil?

          render(:partial => 'user_spent_time', :locals => {:spent_on => spent_on})
        end

        def change_role_activities
          @user = User.find(params[:user_id]) unless params[:user_id].blank?
          @user ||= User.current
          @project = Project.find(params[:project_id])

          new_project_id = params.delete('new_project_id')
          unless new_project_id.blank?
            begin
              @new_project = Project.find(new_project_id)
            rescue ActiveRecord::RecordNotFound
            end
            @time_entry.project = @new_project
          end

          @entity = params[:entity_class].constantize.find(params[:entity_id]) unless params[:entity_class].blank? || params[:entity_id].blank?
          @activities = activity_collection(@user, params[:user_role_id])
          respond_to do |format|
            format.js # change_role_activities.js.erb
          end
        end

        def change_projects_for_bulk_edit
          @visible_projects = get_allowed_projects_for_bulk_edit(params[:term], params[:term].blank? ? nil : 15)
          respond_to do |format|
            format.api
          end
        end

        def change_issues_for_bulk_edit
          respond_to do |format|
            format.api {
              @visible_issues = get_allowed_issues_for_bulk_edit(params[:term], params[:term].blank? ? nil : 15)
            }
            format.html {
              @visible_issues = get_allowed_issues_for_bulk_edit_scope
              render :partial => 'timelog/issues_for_bulk_edit', :locals => {}
            }
          end
        end

        def change_issues_for_timelog
          respond_to do |format|
            format.api {
              @visible_issues = get_allowed_issues_for_bulk_edit(params[:term], params[:term].blank? ? nil : 15)
            }
            format.html {
              @visible_issues = get_allowed_issues_for_bulk_edit_scope
              render :partial => 'timelog/issues_for_timelog', :locals => {}
            }
          end
        end

        private

        def time_entries_clear_activities
          unless @projects.blank?
            @activities = [] if @projects.detect{|p| p.fixed_activity? }
          end
        end

        def load_allowed_projects_for_bulk_edit
          @visible_projects = get_allowed_projects_for_bulk_edit_scope

          if params[:time_entry] && !params[:time_entry][:project_id].blank?
            @selected_visible_project = Project.find(params[:time_entry][:project_id])
          elsif !@time_entry && params[:id]
            find_time_entry
          elsif !@project && params[:project_id]
            find_optional_project
          end

          @selected_visible_project ||= @project
          @selected_visible_project ||= @visible_projects.first if @visible_projects
        end

        def load_allowed_issues_for_bulk_edit
          @visible_issues = get_allowed_issues_for_bulk_edit_scope
        end

        def get_allowed_projects_for_bulk_edit_scope
          if User.current.admin?
            Project.active.non_templates.has_module(:time_tracking)
          else
            User.current.projects.non_templates.has_module(:time_tracking).by_permission(:log_time)
          end
        end

        def get_allowed_issues_for_bulk_edit_scope
          if @selected_visible_project
            scope = @selected_visible_project.issues.visible
            scope = scope.includes(:status).where(IssueStatus.table_name => {:is_closed => false}) unless EasySetting.value('allow_log_time_to_closed_issue')
            scope
          end
        end

        def get_allowed_projects_for_bulk_edit(term = '', limit = nil)
          get_allowed_projects_for_bulk_edit_scope.find(:all, :conditions => ["#{Project.table_name}.name like ?", "%#{term}%"], :limit => limit)
        end

        def get_allowed_issues_for_bulk_edit(term = '', limit = nil)
          if issues = get_allowed_issues_for_bulk_edit_scope
            issues.find(:all, :conditions => ["#{Issue.table_name}.subject like ?", "%#{term}%"], :limit => limit)
          end
        end

        def set_selected_visible_issue
          if @time_entries
            issues = @time_entries.collect{|t| t.issue if t.issue}.compact.uniq
            @selected_visible_issue = issues.first if issues.size == 1
          end
        end

        def set_common_variables
          @only_me = params[:only_me].nil? || params[:only_me] == 'false' ? false : true
          @query.only_me = @only_me

          if @issue
            @query.add_additional_statement("#{Issue.table_name}.root_id = #{@issue.root_id} AND #{Issue.table_name}.lft >= #{@issue.lft} AND #{Issue.table_name}.rgt <= #{@issue.rgt}")
          elsif @project
            @query.add_additional_statement(@project.project_condition(Setting.display_subprojects_issues?))
          end

          if User.current.allowed_to?(:view_all_statements, nil, :global => true)
            if @only_me == true
              @query.add_additional_statement("#{TimeEntry.table_name}.user_id = #{User.current.id}")
            end
          else
            @query.add_additional_statement("#{TimeEntry.table_name}.user_id = #{User.current.id}")
          end
        end

      end
    end

    module InstanceMethods

      def new_with_easy_extensions
        redirect_to(:controller => 'bulk_time_entries', :action => 'index', :project_id => @project, :issue_id => @issue, :back_url => params[:back_url])
      end

      def bulk_update_with_easy_extensions
        attributes = parse_params_for_bulk_time_entry_attributes(params)

        unsaved_time_entries = []
        @time_entries.each do |time_entry|
          time_entry.reload
          if attributes[:project_id].present?
            time_entry.project_id = attributes[:project_id]
          end
          time_entry.safe_attributes = attributes
          call_hook(:controller_time_entries_bulk_edit_before_save, { :params => params, :time_entry => time_entry })
          unless time_entry.save
            logger.info "time entry could not be updated: #{time_entry.errors.full_messages}" if logger && logger.info
            # Keep unsaved time_entry ids to display them in flash error
            unsaved_time_entries << time_entry
          end
        end
        set_flash_from_bulk_time_entry_save(@time_entries, unsaved_time_entries)
        redirect_back_or_default({:controller => 'timelog', :action => 'index', :project_id => @projects.first})
      end

      def index_with_easy_extensions
        if params[:from] && params[:to]
          params[:spent_on] = params[:from] + '|' + params[:to]
          params[:set_filter] = 1
        end
        retrieve_query(EasyTimeEntryQuery)
        sort_init(@query.sort_criteria.empty? ? [["#{TimeEntry.table_name}.spent_on", 'desc']] : @query.sort_criteria)
        sort_update(@query.sortable_columns)

        case params[:format]
        when 'csv', 'pdf', 'ics'
          @limit = Setting.issues_export_limit.to_i
        when 'atom'
          @limit = Setting.feeds_limit.to_i
        when 'xml', 'json'
          @offset, @limit = api_offset_and_limit
        else
          @limit = per_page_option
        end

        set_common_variables

        @entity_count = @query.entity_count
        @entity_pages = Redmine::Pagination::Paginator.new @entity_count, @limit, params['page']

        if request.xhr? && @entity_pages.last_page.to_i < params['page'].to_i
          render_404
          return false
        end

        @offset ||= @entity_pages.offset
        @prepared_entities, @entities = @query.prepare_result({:include_all_entities => true, :order => sort_clause, :offset => @offset, :limit => @limit} )

        @total_hours = @query.entity_sum(:hours)

        if f = @query.filters['spent_on']
          range = get_date_range(f[:operator] == 'date_period_1' ? '1' : '2',f[:values][:period], f[:values][:from], f[:values][:to] )
          @from = range[:from]
          @to = range[:to]

          @easy_attendance_report = EasyAttendanceReport.new(User.current, @from, @to) if EasyAttendance.enabled? && @only_me == true
        end

        respond_to do |format|
          format.html {
            if request.xhr? && params[:easy_query_q]
              render(:partial => 'easy_queries/easy_query_entities_list', :locals => {:query => @query, :entities => @entities})
            else
              render :layout => !request.xhr?
            end
          }
          format.api
          format.csv {send_data(export_to_csv(@entities, @query), :filename => get_export_filename(:csv, @query, l(:label_easy_money_expected_expenses)))}
          format.pdf {send_data(export_to_pdf(@prepared_entities, @query, :default_title => l(:label_easy_money_expected_expenses)), :filename => get_export_filename(:pdf, @query, l(:label_easy_money_expected_expenses)))}
          format.atom {render_feed(@entities, :title => l(:label_spent_time))}
        end
      end

      def create_with_easy_extensions
        @time_entry ||= TimeEntry.new(:project => @project, :issue => @issue, :spent_on => User.current.today)

        if params[:time_entry] && params[:time_entry][:user_id] && User.current.admin?
          @time_entry.user = User.find_by_id(params[:time_entry][:user_id])
        else
          @time_entry.user = User.current
        end

        @time_entry.safe_attributes = params[:time_entry]

        call_hook(:controller_timelog_edit_before_save, { :params => params, :time_entry => @time_entry })

        if @time_entry.save
          respond_to do |format|
            format.html {
              flash[:notice] = l(:notice_successful_create)
              if params[:continue]
                if params[:project_id]
                  redirect_to :action => 'new', :project_id => @time_entry.project, :issue_id => @time_entry.issue,
                  :time_entry => {:issue_id => @time_entry.issue_id, :activity_id => @time_entry.activity_id},
                  :back_url => params[:back_url]
                else
                  redirect_to :action => 'new',
                  :time_entry => {:project_id => @time_entry.project_id, :issue_id => @time_entry.issue_id, :activity_id => @time_entry.activity_id},
                  :back_url => params[:back_url]
                end
              else
                redirect_back_or_default :action => 'index', :project_id => @time_entry.project
              end
            }
            format.api  { render :action => 'show', :status => :created, :location => time_entry_url(@time_entry) }
          end
        else
          respond_to do |format|
            format.html { render :action => 'new' }
            format.api  { render_validation_errors(@time_entry) }
          end
        end
      end

      def set_flash_from_bulk_time_entry_save_with_easy_extensions(time_entries, unsaved_time_entries)
        if unsaved_time_entries.empty?
          flash[:notice] = l(:notice_successful_update) unless time_entries.empty?
        else
          flash[:error] = (l(:notice_failed_to_save_time_entries, :count => unsaved_time_entries.size, :total => time_entries.size, :ids => '#' + unsaved_time_entry_ids.join(', #')) + '<br />'.html_safe +
              unsaved_time_entries.collect{|t| view_context.content_tag(:span,
                view_context.link_to(ERB::Util.h("#{format_date(t.spent_on)} -- #{t.project}:  #{l(:label_f_hour_plural, :value => t.hours)}"), { :action => 'edit', :id => t }).html_safe + ': ' +
                  t.errors.full_messages.join(', ')
              )}.join('<br />').html_safe).html_safe
        end
      end

      def report_with_easy_extensions
        retrieve_query(EasyTimeEntryQuery)
        @query.export_formats.delete(:pdf)

        set_common_variables

        scope = @query.create_entity_scope

        @report = Redmine::Helpers::TimeReport.new(@project, @issue, params[:criteria], params[:columns], scope)

        @total_hours = @query.entity_sum(:hours)

        respond_to do |format|
          format.html { render :layout => !request.xhr? }
          format.csv  { send_data(report_to_csv(@report), :type => 'text/csv; header=present', :filename => 'timelog.csv') }
        end
      end

      private

      def find_optional_project_with_easy_extensions
        if !params[:issue_id].blank?
          @issue = Issue.find(params[:issue_id])
          @project = @issue.project
        elsif !params[:project_id].blank?
          @project = Project.find(params[:project_id])
        end
        if @project && !@project.module_enabled?(:time_tracking)
          render_404
          return
        end
        deny_access unless User.current.allowed_to?(:view_time_entries, @project, :global => true)
      end

      def time_entry_scope_with_easy_extensions
        scope = TimeEntry.visible(User.current, :archive => :true)
        if @issue
          scope = scope.on_issue(@issue)
        elsif @project
          scope = scope.on_project(@project, Setting.display_subprojects_issues?)
        end

        date_range = get_date_range(params[:period_type], params[:period], params[:from], params[:to])
        @from, @to = date_range[:from], date_range[:to]

        if @from
          scope = scope.where(["#{TimeEntry.table_name}.spent_on >= ?", @from])
        end

        if @to
          scope = scope.where(["#{TimeEntry.table_name}.spent_on <= ?", @to])
        end

        @only_me = params[:only_me] == 'true'
        if @only_me
          scope = scope.where(["#{TimeEntry.table_name}.user_id = ?", User.current.id])
        end

        scope
      end

    end
  end
end
EasyExtensions::PatchManager.register_controller_patch 'TimelogController', 'EasyPatch::TimelogControllerPatch'
