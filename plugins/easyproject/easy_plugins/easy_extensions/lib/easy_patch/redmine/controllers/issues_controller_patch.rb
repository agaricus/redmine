module EasyPatch
  module IssuesControllerPatch

    def self.included(base)
      base.send(:include, InstanceMethods)

      base.class_eval do

        menu_item :calendar, :only => :calendar
        menu_item :gantt, :only => :gantt

        before_filter :delete_time_entry_with_zero_hours, :only => [:update]
        before_filter :build_new_issue_from_params, :only => [:new, :create, :update_form]
        before_filter :change_back_url_for_external_mails, :only => [:update]

        after_filter :extended_flash_notice, :only => [:create, :update]

        helper :entity_attribute
        include EntityAttributeHelper
        helper :easy_query
        include EasyQueryHelper
        helper :easy_journal
        include EasyJournalHelper
        helper :easy_ical
        include EasyIcalHelper

        alias_method_chain :new, :easy_extensions
        alias_method_chain :create, :easy_extensions
        alias_method_chain :edit, :easy_extensions
        alias_method_chain :index, :easy_extensions
        alias_method_chain :show, :easy_extensions
        alias_method_chain :update, :easy_extensions
        alias_method_chain :bulk_edit, :easy_extensions
        alias_method_chain :bulk_update, :easy_extensions
        alias_method_chain :destroy, :easy_extensions
        alias_method_chain :retrieve_previous_and_next_issue_ids, :easy_extensions
        alias_method_chain :parse_params_for_bulk_issue_attributes, :easy_extensions
        alias_method_chain :find_optional_project, :easy_extensions
        alias_method_chain :find_project, :easy_extensions

        private

        def delete_time_entry_with_zero_hours
          time_entry = TimeEntry.new(:issue => @issue, :project => @issue.project)
          time_entry.safe_attributes = params[:time_entry]
          params.delete(:time_entry) if time_entry.hours == 0
        end

        def issue_403
          (render_403; return false) unless User.current.allowed_to?(:edit_issues, @issue.project) || User.current.allowed_to?(:add_issue_notes, @issue.project) || (User.current.allowed_to?(:edit_own_issue, @issue.project) && @issue.author.id == User.current.id)
        end

        def extended_flash_notice
          return if Setting.bcc_recipients? || User.current.mail_notification.blank? || User.current.mail_notification == 'none' || User.current.pref[:no_notification_ever] == true || @issue.project.try(:is_planned)

          issue_recipients = @issue.recipients

          issue_watchers = (@issue.watcher_recipients - issue_recipients)

          recipients = (issue_watchers + issue_recipients).compact.uniq
          author ||= User.current
          recipients.delete(author.mail) if author.pref.no_self_notified
          if !flash[:notice].blank? && recipients.any?
            flash[:notice] += content_tag(:p, l(:label_issue_notice_recipients) + recipients.join('; '), :class => 'email-was-sent')
            flash[:notice] = flash[:notice].html_safe
          end
        end

        def change_back_url_for_external_mails(issue_id = nil, original_back_url = nil)
          issue_id ||= params[:id]
          original_back_url ||= params[:back_url]

          return if issue_id.blank?

          if params[:issue] && params[:issue][:send_to_external_mails] == 'true' && request.format == :html
            params[:back_url] = url_for(:controller => 'easy_issues', :action => 'preview_external_email', :id => issue_id, :back_url => original_back_url)
          end
        end

      end
    end

    module InstanceMethods

      def bulk_edit_with_easy_extensions
        @issues.sort!
        @copy = params[:copy].present?
        @notes = params[:notes]

        if params[:issue] && params[:issue][:project_id]
          if User.current.allowed_to?(:move_issues, @projects)
            @target_project = Project.where(Project.allowed_to_condition(User.current, :move_issues)).where(:id => params[:issue][:project_id]).first
            if @target_project
              target_projects = [@target_project]
            end
          end
        end
        target_projects ||= @projects

        if @copy
          @available_statuses = [IssueStatus.default]
        else
          @available_statuses = @issues.map(&:new_statuses_allowed_to).reduce(:&)
        end
        @custom_fields = target_projects.map{|p|p.all_issue_custom_fields.visible}.reduce(:&)
        @assignables = target_projects.map(&:assignable_users).reduce(:&)
        @trackers = target_projects.map(&:trackers).reduce(:&)
        @versions = target_projects.map {|p| p.shared_versions.open}.reduce(:&)
        @categories = target_projects.map {|p| p.issue_categories}.reduce(:&)
        @watchers = target_projects.map {|p| p.members.collect(&:user)}.reduce(:&)
        if @copy
          @attachments_present = @issues.detect {|i| i.attachments.any?}.present?
          @subtasks_present = @issues.detect {|i| !i.leaf?}.present?
        end

        @safe_attributes = @issues.map(&:safe_attribute_names).reduce(:&)

        @issue_params = params[:issue] || {}
        @issue_params[:custom_field_values] ||= {}
      end

      def bulk_update_with_easy_extensions
        @issues.sort!
        @copy = params[:copy].present?
        attributes = parse_params_for_bulk_issue_attributes(params)

        unsaved_issues = []
        saved_issues = []

        if @copy && params[:copy_subtasks].present?
          # Descendant issues will be copied with the parent task
          # Don't copy them twice
          @issues.reject! {|issue| @issues.detect {|other| issue.is_descendant_of?(other)}}
        end

        @issues.each do |orig_issue|
          orig_issue.reload
          if @copy
            issue = orig_issue.copy({},
              :attachments => params[:copy_attachments].present?,
              :subtasks => params[:copy_subtasks].present?
            )
            issue.attributes_for_descendants = attributes.dup
          else
            issue = orig_issue
          end
          journal = issue.init_journal(User.current, params[:notes])
          issue.safe_attributes = attributes.dup
          if issue.start_date && issue.due_date && issue.start_date > issue.due_date
            if attributes.has_key?('start_date')
              issue.due_date = issue.start_date
            else
              issue.start_date = issue.due_date
            end
          end
          call_hook(:controller_issues_bulk_edit_before_save, { :params => params, :issue => issue })
          saved = false
          begin
            saved = issue.save
          rescue ActiveRecord::StaleObjectError
            issue.reload
            issue.safe_attributes = attributes.dup
            saved = issue.save
          end
          if saved
            saved_issues << issue
            call_hook(:controller_issues_bulk_edit_after_save, { :params => params, :issue => issue })
          else
            # Keep unsaved issue ids to display them in flash error
            unsaved_issues << issue
          end
        end

        if unsaved_issues.empty?
          flash[:notice] = l(:notice_successful_update) unless saved_issues.empty?
          if params[:follow]
            if @issues.size == 1 && saved_issues.size == 1
              redirect_to issue_path(saved_issues.first)
            elsif saved_issues.map(&:project).uniq.size == 1
              redirect_to project_issues_path(saved_issues.map(&:project).first)
            end
          else
            redirect_back_or_default _project_issues_path(@project)
          end
        else
          @saved_issues = @issues
          @unsaved_issues = unsaved_issues
          @issues = Issue.visible.find_all_by_id(@unsaved_issues.map(&:id))
          bulk_edit
          render :action => 'bulk_edit'
        end
      end

      def index_with_easy_extensions
        retrieve_query(EasyIssueQuery)
        sort_init(@query.sort_criteria_init)
        sort_update(@query.sortable_columns)

        additional_statement = ''
        if @project
          if @project.easy_is_easy_template
            additional_statement = "#{Project.table_name}.easy_is_easy_template=#{@query.connection.quoted_true}"
          else
            additional_statement = "#{Project.table_name}.easy_is_easy_template=#{@query.connection.quoted_false}"
          end
        else
          additional_statement = "#{Project.table_name}.easy_is_easy_template=#{@query.connection.quoted_false}"
        end

        if @query.additional_statement.blank?
          @query.additional_statement = additional_statement
        else
          @query.additional_statement << ' AND ' + additional_statement
        end

        if @query.valid?
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

          @issue_count = @query.entity_count
          @issue_pages = Redmine::Pagination::Paginator.new @issue_count, @limit, params['page']

          if request.xhr? && @issue_pages.last_page.to_i < params['page'].to_i
            render_404
            return false
          end

          #          export = ActiveSupport::OrderedHash.new
          #          export[:atom] = {:url => {:key => User.current.rss_key}}
          #          export[:csv] = @query.export_formats[:csv]
          #          export[:pdf] = @query.export_formats[:pdf]
          #          export[:ics] = {:caption => 'iCal', :url => {:protocol => 'webcal', :key => User.current.api_key, :only_path => false}, :title => l(:title_other_formats_links_ics_outlook)}
          #          @query.export_formats = export

          @offset ||= @issue_pages.offset
          @prepared_issues, @issues = @query.prepare_result(:include_all_entities => true, :order => sort_clause, :offset => @offset, :limit => @limit)
          @issue_count_by_group = @query.entity_count_by_group

          respond_to do |format|
            format.html {
              if request.xhr? && params[:easy_query_q]
                render(:partial => 'easy_queries/easy_query_entities_list', :locals => {:query => @query, :entities => @prepared_issues})
              else
                render :template => 'issues/index', :layout => !request.xhr?
              end
            }
            format.api  {
              Issue.load_visible_relations(@issues) if include_in_api_response?('relations')
            }
            format.atom { render_feed(@issues, :title => "#{@project || Setting.app_title}: #{l(:label_issue_plural)}") }
            format.csv  { send_data(export_to_csv(@issues, @query), :filename => get_export_filename(:csv, @query)) }
            format.pdf  { send_data(export_to_pdf(@prepared_issues, @query), :type => 'application/pdf', :filename => get_export_filename(:pdf, @query)) }
            format.ics  { send_data(issues_to_ical(@issues), :filename => get_export_filename(:ics, @query), :type => Mime[:ics].to_s+'; charset=utf-8') }
          end
        else
          respond_to do |format|
            format.html { render(:template => 'issues/index', :layout => !request.xhr?) }
            format.any(:atom, :csv, :pdf, :ics) { render(:nothing => true) }
            format.api { render_validation_errors(@query) }
          end
        end
      rescue ActiveRecord::RecordNotFound
        render_404
      end

      def show_with_easy_extensions
        @journals = @issue.journals.includes(:journalized, :user, :details).reorder("#{Journal.table_name}.id ASC").all
        @journals.each_with_index {|j,i| j.indice = i+1}
        @journals.reject!(&:private_notes?) unless User.current.allowed_to?(:view_private_notes, @issue.project)
        Journal.preload_journals_details_custom_fields(@journals)
        # TODO: use #select! when ruby1.8 support is dropped
        @journals.reject! {|journal| !journal.notes? && journal.visible_details.empty?}
        @journals.reverse! if User.current.wants_comments_in_reverse_order?

        @changesets = @issue.changesets.visible.all
        @changesets.reverse! if User.current.wants_comments_in_reverse_order?

        @relations = @issue.relations.select {|r| r.other_issue(@issue) && r.other_issue(@issue).visible? }
        respond_to do |format|
          format.html {
            retrieve_previous_and_next_issue_ids
            render :template => 'issues/show'}
          format.api
          format.atom { render :template => 'journals/index', :layout => false, :content_type => 'application/atom+xml' }
          format.pdf  {
            pdf = issue_to_pdf(@issue, :journals => @journals)
            send_data(pdf, :type => 'application/pdf', :filename => "#{@issue.to_s}.pdf")
          }
          format.ics  { send_data(issue_to_ical(@issue), :filename => "#{@issue.to_s}.ics", :type => Mime[:ics].to_s+'; charset=utf-8') }
        end

      end

      def edit_with_easy_extensions
        return unless update_issue_from_params

        respond_to do |format|
          format.html { render :layout => !request.xhr? }
          format.xml  { }
          format.js  { render :layout => !request.xhr? }
        end
      end

      def update_with_easy_extensions
        return unless update_issue_from_params
        @issue.save_attachments(params[:attachments] || (params[:issue] && params[:issue][:uploads]))
        saved = false
        begin
          saved = save_issue_with_child_records
        rescue ActiveRecord::StaleObjectError
          @conflict = true
          if params[:last_journal_id]
            @conflict_journals = @issue.journals_after(params[:last_journal_id]).all
            @conflict_journals.reject!(&:private_notes?) unless User.current.allowed_to?(:view_private_notes, @issue.project)
          end
        end

        if saved
          render_attachment_warning_if_needed(@issue)

          respond_to do |format|
            format.html {
              flash[:notice] = l(:notice_successful_update) unless @issue.current_journal.new_record?
              redirect_back_or_default issue_path(@issue)
            }
            format.api  { render_api_ok }
          end
        else
          respond_to do |format|
            format.html { render :action => 'edit', :layout => !request.xhr?, :status => :unprocessable_entity }
            format.api  { render_validation_errors(@issue) }
          end
        end
      end

      def create_with_easy_extensions
        @issue.description ||= ''
        if params[:subtask_for_id] && Issue.visible(User.current).exists?(params[:subtask_for_id].to_i)
          @issue.parent_issue_id = params[:subtask_for_id]
        end
        call_hook(:controller_issues_new_before_save, { :params => params, :issue => @issue })
        @issue.save_attachments(params[:attachments] || (params[:issue] && params[:issue][:uploads]))
        if @issue.save
          call_hook(:controller_issues_new_after_save, { :params => params, :issue => @issue})
          respond_to do |format|
            format.html {
              if params[:for_dialog]
                render :text => @issue.id
              else
                render_attachment_warning_if_needed(@issue)
                flash[:notice] = l(:notice_issue_successful_create, :id => view_context.link_to("#{@issue.to_s}", issue_path(@issue), :title => @issue.subject)).html_safe

                if params[:continue]
                  next_url = { :controller => 'issues', :action => 'new', :project_id => @project, :issue => {:tracker_id => @issue.tracker, :parent_issue_id => @issue.parent_issue_id}.reject {|k,v| v.nil?} }
                else
                  next_url = { :controller => 'issues', :action => 'show', :id => @issue }
                end
                change_back_url_for_external_mails(@issue.id, url_for(next_url))
                redirect_back_or_default(next_url)
              end
            }
            format.js
            format.api  { render :action => 'show', :status => :created, :location => issue_url(@issue) }
          end
        else
          respond_to do |format|
            format.html do
              if params[:for_dialog]
                render :partial => 'easy_issues/new_for_dialog'
              else
                render :controller => 'issues', :action => 'new'
              end
            end
            format.js
            format.api  { render_validation_errors(@issue) }
          end
        end
      end

      def new_with_easy_extensions
        future_parent_issue = Issue.visible(User.current).where(:id => params[:subtask_for_id]).first
        if future_parent_issue
          # Maybe we could write some UI for this feature
          attributes_for_inheritance = [:fixed_version_id]
          attributes_for_inheritance.each do |attribute|
            @issue.send("#{attribute}=", future_parent_issue.send(attribute))
          end
        end
        if @project && @project.start_date && Setting.default_issue_start_date_to_creation_date? && !EasySetting.value('project_calculate_start_date') && Date.today < @project.start_date
          @issue.start_date = @project.start_date
        end
        new_without_easy_extensions
      end

      def destroy_with_easy_extensions
        @hours = TimeEntry.where(:issue_id => @issues.map(&:id)).sum(:hours).to_f
        if @hours > 0
          case params[:todo]
          when 'destroy'
            # nothing to do
          when 'nullify'
            TimeEntry.update_all('issue_id = NULL', ['issue_id IN (?)', @issues])
          when 'reassign'
            reassign_to = @project.issues.find_by_id(params[:reassign_to_id]) if params[:reassign_to_id]
            if reassign_to.nil?
              flash.now[:error] = l(:error_issue_not_found_in_project)
              return
            else
              TimeEntry.update_all("issue_id = #{reassign_to.id}", ['issue_id IN (?)', @issues])
            end
          else
            # display the destroy form if it's a user request
            return unless api_request?
          end
        end
        @issues.each do |issue|
          begin
            issue.reload.destroy
          rescue ::ActiveRecord::RecordNotFound # raised by #reload if issue no longer exists
            # nothing to do, issue was already deleted (eg. by a parent)
          end
        end
        respond_to do |format|
          format.html {
            if @project
              redirect_back_or_default project_issues_path(@project)
            else
              redirect_back_or_default({:controller => 'issues', :action => 'index'})
            end
          }
          format.api  { render_api_ok }
        end
      end

      def retrieve_previous_and_next_issue_ids_with_easy_extensions
        return  #speed boost, low used feature
        retrieve_query_from_session(EasyIssueQuery)
        if @query
          sort_init(@query.sort_criteria.empty? ? [['id', 'desc']] : @query.sort_criteria)
          sort_update(@query.sortable_columns, 'issues_index_sort')
          limit = 500
          issue_ids = @query.entities_ids(:order => sort_clause, :limit => (limit + 1), :include => [:assigned_to, :tracker, :priority, :category, :fixed_version])
          if (idx = issue_ids.index(@issue.id)) && idx < limit
            if issue_ids.size < 500
              @issue_position = idx + 1
              @issue_count = issue_ids.size
            end
            @prev_issue_id = issue_ids[idx - 1] if idx > 0
            @next_issue_id = issue_ids[idx + 1] if idx < (issue_ids.size - 1)
            @prev_issue = Issue.where(:id => @prev_issue_id).select([:id, :subject, :project_id]).first if @prev_issue_id
            @next_issue = Issue.where(:id => @next_issue_id).select([:id, :subject, :project_id]).first if @next_issue_id
          end
        end
      end

      def parse_params_for_bulk_issue_attributes_with_easy_extensions(params)
        %w(start_date due_date parent_issue_id).each do |attr_name|
          type = params[:issue].delete("#{attr_name}_type")
          if type == 'unchanged'
            params[:issue].delete(attr_name)
          elsif type && params[:issue][attr_name].blank?
            params[:issue][attr_name] = 'none'
          end
        end
        parse_params_for_bulk_issue_attributes_without_easy_extensions(params)
      end

      def find_optional_project_with_easy_extensions
        #easy query workaround
        return if params[:set_filter] == '1' && params[:project_id] && params[:project_id].match(/\A(=|\!|\!\*|\*)\S*/)
        find_optional_project_without_easy_extensions
      end

      def find_project_with_easy_extensions
        project_id = params[:project_id] || (params[:issue] && params[:issue][:project_id])
        @project = Project.find(project_id)
      rescue ActiveRecord::RecordNotFound
        render_404
      end
    end
  end
end
EasyExtensions::PatchManager.register_controller_patch 'IssuesController', 'EasyPatch::IssuesControllerPatch'
