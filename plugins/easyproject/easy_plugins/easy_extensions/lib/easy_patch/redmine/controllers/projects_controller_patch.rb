module EasyPatch
  module ProjectsControllerPatch

    def self.included(base)
      base.send(:include, InstanceMethods)

      base.class_eval do
        menu_item :projects, :only => [:index, :new, :create]

        default_search_scope :projects

        before_filter :find_project, :except => [ :index, :list, :new, :create, :toggle_custom_fields_on_project_form, :search, :load_allowed_parents]
        before_filter :find_project_2, :only => [:load_allowed_parents]

        skip_before_filter :require_admin, :only => [:archive, :copy, :destroy]
        before_filter :authorize, :only => [:archive, :copy, :show, :personalize_show, :edit_custom_fields_form, :update_custom_fields_form, :destroy, :load_allowed_parents]
        before_filter :authorize_easy_project_template, :except => [:index, :list, :new, :create, :toggle_custom_fields_on_project_form, :search]
        before_filter :change_show_rendering, :only => :show
        before_filter :change_personalize_show_rendering, :only => :personalize_show
        before_filter :find_relations, :only => [:settings]
        before_filter :delete_page_modules, :only => [:destroy]
        before_filter :authorize_easy_project_editable, :only => [:edit, :settings, :update]

        # cache_sweeper :my_page_my_projects_simple_sweeper, :projects_index_sweeper

        rescue_from EasyQuery::StatementInvalid, :with => :query_statement_invalid

        helper :journals
        include JournalsHelper
        helper :easy_journal
        include EasyJournalHelper
        helper :easy_query
        include EasyQueryHelper
        helper :entity_attribute
        include EntityAttributeHelper
        helper :easy_page_modules
        include EasyPageModulesHelper
        helper :easy_setting
        include EasySettingHelper
        helper :easy_project_relations
        include EasyProjectRelationsHelper

        alias_method_chain :archive, :easy_extensions
        alias_method_chain :close, :easy_extensions
        alias_method_chain :copy, :easy_extensions
        alias_method_chain :create, :easy_extensions
        alias_method_chain :edit, :easy_extensions
        alias_method_chain :index, :easy_extensions
        alias_method_chain :modules, :easy_extensions
        alias_method_chain :new, :easy_extensions
        alias_method_chain :reopen, :easy_extensions
        alias_method_chain :settings, :easy_extensions
        alias_method_chain :show, :easy_extensions
        alias_method_chain :unarchive, :easy_extensions
        alias_method_chain :update, :easy_extensions

        def authorize_archive
          authorize unless User.current.admin?
        end

        def favorite
          if User.current.favorite_projects.where(:id => @project.id).exists?
            User.current.favorite_projects.delete(@project)
            @favorited = false
          else
            User.current.favorite_projects << @project
            @favorited = true
          end

          respond_to do |format|
            format.js
          end
        end

        def personalize_show
        end

        def toggle_custom_fields_on_project_form
          add_new_cf = params[:checked].to_boolean if params[:checked]

          params[:project][:project_custom_field_ids] = params[:project_custom_field_ids] if params[:project_custom_field_ids]

          @project = Project.find(params[:id], :include => :custom_values) if params[:id]
          @project ||= Project.new
          @project.safe_attributes = params[:project]

          # useless?
          if add_new_cf && !@project.custom_field_values.detect{|cfv| cfv.custom_field_id == params[:new_custom_field_id].to_i}
            cv = @project.custom_values.where(:custom_field_id => params[:new_custom_field_id]).first
            cv ||= CustomValue.new(:customized => @project, :custom_field_id => params[:new_custom_field_id])

            new_cfv = CustomFieldValue.new; new_cfv.custom_field = cv.custom_field; new_cfv.value = cv.value || ''
            @project.custom_field_values << new_cfv
          elsif !add_new_cf
            @project.custom_field_values.delete_if{|i| i.custom_field_id == params[:new_custom_field_id].to_i}
          end

          render :partial => 'form_project_custom_fields', :locals => {:custom_field_values => @project.custom_field_values.sort_by{|i| i.custom_field.position }, :project => @project}
        end

        def search
          @query = EasyProjectQuery.new(:name => '_')
          if params[:for] && params[:for] == 'admin'
            @query.additional_statement = "#{Project.table_name}.easy_is_easy_template=#{@query.connection.quoted_false}"
          else
            @query.additional_statement = "#{Project.table_name}.easy_is_easy_template=#{@query.connection.quoted_false} AND #{Project.visible_condition(User.current)}"
          end
          @query.from_params(params)
          @status = params[:status] || Project::STATUS_ACTIVE.to_s
          @query.filters['status'] = {:operator => '=', :values => [@status]}
          @query.user = User.current
          @query.project = Project.find(params[:project_id]) unless params[:project_id].blank?

          @question = params[:easy_query_q] || ''
          @question.strip!

          # extract tokens from the question
          # eg. hello "bye bye" => ["hello", "bye bye"]
          @tokens = @question.scan(%r{((\s|^)"[\s\w]+"(\s|$)|\S+)}).collect {|m| m.first.gsub(%r{(^\s*"\s*|\s*"\s*$)}, '')}
          # tokens must be at least 2 characters long
          @tokens = @tokens.uniq.select {|w| w.length > 1 }
          @entity_count = @query.search_freetext_count(@tokens)

          # no more than 5 tokens to search for
          @tokens.slice! 5..-1 if @tokens.size > 5
          @projects = @query.search_freetext(@tokens, {:order => "#{Project.table_name}.lft"})
          if @projects.any?
            add_non_filtered_projects
            respond_to do |format|
              format.html {
                @project_plus_buttons = {}
                @project_hidden_rows = {}
                view = params[:for].blank? ? 'projects' : "#{params[:for]}/projects"
                render :layout => false, :partial => view, :locals => {:query => @query, :projects => @projects, :options => {:disable_sort => true}}
              }
              format.csv {send_data(projects_to_csv(@projects, @query), :type => 'text/csv; header=present', :filename => get_export_filename(:csv, @query))}
              format.pdf {send_data(projects_to_pdf(@projects, @query), :type => 'application/pdf', :filename => get_export_filename(:pdf, @query))}
            end

          else
            render :text => content_tag(:p, l(:label_no_data), :class => 'nodata')
          end

        end

        def load_allowed_parents
          options = {}
          options[:force] = params[:force] unless params[:force].blank?

          term = params[:term]
          limit = term.blank? ? 100 : 15

          scope = @project.project.allowed_parents_scope(options)
          scope = scope.where(["#{Project.table_name}.name like ?", "%#{term}%"]).limit(limit).reorder("#{Project.table_name}.lft")

          @self_only = params[:term].blank?
          @projects = scope.all

          respond_to do |format|
            format.api
          end
        end

        def edit_custom_fields_form
          respond_to do |format|
            format.js { render :partial => 'projects/edit_custom_fields_form', :locals => {:project => @project}}
          end
        end

        def update_custom_fields_form
          @project.init_journal(User.current, params[:notes])
          @project.safe_attributes = params[:project]

          if @project.save
            respond_to do |format|
              format.js { render :partial => 'common/easy_redirect', :locals => {:back_url => params[:back_url] || url_for(:controller => 'projects', :action => 'show', :id => @project)} }
            end
          else
            respond_to do |format|
              format.js { render :partial => 'projects/edit_custom_fields_form', :locals => {:project => @project} }
            end
          end
        end

        private

        def find_relations
          @relations = @project.relations.select {|r| r.other_project(@project) && r.other_project(@project).visible? }
        end

        def change_show_rendering
          render_action_as_easy_page(EasyPage.page_project_overview, nil, @project.id, url_for(:controller => 'projects', :action => 'show', :id => @project), false, {:project => @project})
        end

        def change_personalize_show_rendering
          render_action_as_easy_page(EasyPage.page_project_overview, nil, @project.id, url_for(:controller => 'projects', :action => 'show', :id => @project), true, {:project => @project})
        end

        # Rescues an invalid query statement. Just in case...
        def query_statement_invalid(exception)
          logger.error "EasyQuery::StatementInvalid: #{exception.message}" if logger
          session.delete('easy_project_query')
          sort_clear if respond_to?(:sort_clear)
          render_error l(:label_error_project_query)
        end

        def authorize_easy_project_template
          if @project && !@project.new_record? && @project.easy_is_easy_template? && !User.current.allowed_to?(:edit_project_template, @project)
            deny_access
          end
        end

        def delete_page_modules
          if @project && (api_request? || params[:confirm])
            @project.children.each do |child|
              Project.delete_easy_page_modules child.id
            end

            Project.delete_easy_page_modules @project.id
          end
        end

        def find_project_2
          @project = Project.find(params[:id]) if params[:id]
          @project ||= Project.new
        end

        def authorize_easy_project_editable
          if @project.editable?
            true
          else
            deny_access
          end
        end

      end
    end

    module InstanceMethods

      def show_with_easy_extensions
        params[:jump] = 'issues' if in_mobile_view?
        if params[:jump]
          # try to redirect to the requested menu item
          redirect_to_project_menu_item(@project, params[:jump])
        end
      end

      def index_with_easy_extensions
        retrieve_query(EasyProjectQuery)
        sort_init(@query.sort_criteria_init)
        sort_update({'lft' => "#{Project.table_name}.lft"}.merge(@query.sortable_columns))

        @query.add_additional_statement "#{Project.table_name}.easy_is_easy_template=#{@query.connection.quoted_false}"

        if @query.valid?
          respond_to do |format|
            format.html {
              if !params[:root_id]
                if @query.only_favorited?
                  @projects = @query.entities(:order => sort_clause)
                  add_non_filtered_projects
                  @only_favorited = true
                else
                  @entity_count = @query.entity_count
                  @limit = per_page_option
                  @project_pages = Redmine::Pagination::Paginator.new @entity_count, @limit, params['page']
                  @offset = params[:offset].blank? ? @project_pages.offset : params[:offset].to_i
                  if request.xhr? && @offset >= @entity_count
                    render_404
                    return false
                  end
                  if @query.grouped?
                    @projects = @query.entities(:order => sort_clause, :offset => @offset, :limit => @limit)
                  else
                    @children_count, @projects = @query.roots(:offset => @offset, :limit => @limit)
                  end
                end
              else
                root = Project.find(params[:root_id])
                @query.add_additional_statement "#{Project.table_name}.id != #{params[:root_id]}"
                @query.add_additional_statement "#{Project.table_name}.lft > #{root.lft}"
                @query.add_additional_statement "#{Project.table_name}.rgt < #{root.rgt}"
                @projects = @query.entities(:order => sort_clause, :offset => @offset, :limit => @limit)
                add_non_filtered_projects(:exclude_roots => true) unless @query.grouped?
              end

              render :layout => !request.xhr?
            }
            format.api  {
              @offset, @limit = api_offset_and_limit
              @project_count = @query.entity_count
              @projects = @query.entities(:order => sort_clause, :offset => @offset, :limit => @limit)
            }
            format.csv  {
              @projects = @query.entities(:order => sort_clause, :offset => @offset, :limit => @limit)
              add_non_filtered_projects if params[:group_by].blank?
              send_data(projects_to_csv(@projects, @query), :type => 'text/csv; header=present', :filename => get_export_filename(:csv, @query))

            }
            format.pdf  {
              @projects = @query.entities(:order => sort_clause, :offset => @offset, :limit => @limit)
              add_non_filtered_projects if params[:group_by].blank?
              send_data(projects_to_pdf(@projects, @query), :type => 'application/pdf', :filename => get_export_filename(:pdf, @query))
            }
            format.atom {
              @projects = @query.entities(:order => 'created_on DESC', :limit => Setting.feeds_limit.to_i)
              render_feed(@projects, :title => "#{Setting.app_title}: #{l(:label_project_latest)}")
            }
          end
        else
          @projects = Project.visible.find(:all, :order => 'lft')
        end
      end

      def new_with_easy_extensions
        @project_custom_fields = ProjectCustomField.order(:name).all
        new_without_easy_extensions
        call_hook(:controller_projects_new, {:params => params, :project => @project})
      end

      def create_with_easy_extensions
        @project_custom_fields = ProjectCustomField.order(:name).all
        @issue_custom_fields = IssueCustomField.sorted.all
        @trackers = Tracker.sorted.all
        @project = Project.new
        @project.safe_attributes = params[:project]
        call_hook(:controller_projects_create_before_save, { :params => params, :project => @project })
        if validate_parent_id && @project.save
          @project.set_allowed_parent!(params[:project]['parent_id']) if params[:project].has_key?('parent_id')
          # Add current user as a project member if he is not admin
          unless User.current.admin?
            if @project.root?
              r = Role.givable.find_by_id(Setting.new_project_user_role_id.to_i) || Role.givable.first
            else
              r = Role.givable.find_by_id(EasySetting.value('new_subproject_user_role_id').to_i) || Role.givable.first
            end

            m = Member.new(:user => User.current, :roles => [r])
            @project.members << m
          end
          call_hook(:controller_projects_create_after_save, { :params => params, :project => @project })
          respond_to do |format|
            format.html {
              flash[:notice] = l(:notice_successful_create)
              if params[:continue]
                attrs = {:parent_id => @project.parent_id}.reject {|k,v| v.nil?}
                redirect_to new_project_path(attrs)
              else
                redirect_to settings_project_path(@project)
              end
            }
            format.api  { render :action => 'show', :status => :created, :location => url_for(:controller => 'projects', :action => 'show', :id => @project.id) }
          end
        else
          respond_to do |format|
            format.html { render :action => 'new' }
            format.api  { render_validation_errors(@project) }
          end
        end
      end

      def edit_with_easy_extensions
        @journals = @project.journals.includes(:user, :details).reorder("#{Journal.table_name}.id ASC").all
        @journals.each_with_index {|j,i| j.indice = i+1}
        @journals.reject!(&:private_notes?) unless User.current.allowed_to?(:view_private_notes, @project)
        @journals.reverse! if User.current.wants_comments_in_reverse_order?
        edit_without_easy_extensions
      end

      def update_with_easy_extensions
        @project.init_journal(User.current, params[:notes])
        update_without_easy_extensions
      end

      def settings_with_easy_extensions
        @project_custom_fields = ProjectCustomField.order(:name).all
        save_easy_settings(@project) unless request.get?
        if params[:tab] == 'versions'
          retrieve_query(EasyVersionQuery)
          sort_init(@query.sort_criteria.empty? ? ['effective_date', 'asc'] : @query.sort_criteria)
          sort_update(@query.sortable_columns)

          @versions = @query.prepare_result(:order => sort_clause)

          respond_to do |format|
            format.html {
              render :layout => !request.xhr?
            }
            format.csv  {
              send_data(export_to_csv(@versions, @query), :filename => get_export_filename(:csv, @query))
            }
            format.pdf  {
              send_data(export_to_pdf(@versions, @query), :filename => get_export_filename(:pdf, @query))
            }
          end
        elsif params[:tab].blank? || params[:tab] == 'info'
          @journals = @project.journals.includes(:user, :details).reorder("#{Journal.table_name}.id ASC").all
          @journals.each_with_index {|j,i| j.indice = i+1}
          @journals.reject!(&:private_notes?) unless User.current.allowed_to?(:view_private_notes, @project)
          @journals.reverse! if User.current.wants_comments_in_reverse_order?
        end
        settings_without_easy_extensions
      end

      def modules_with_easy_extensions
        save_easy_settings(@project)
        modules_without_easy_extensions
      end

      def copy_with_easy_extensions
        @project_custom_fields = ProjectCustomField.order(:name).all
        @issue_custom_fields = IssueCustomField.sorted.all
        @trackers = Tracker.sorted.all
        @root_projects = Project.find(:all,
          :conditions => "parent_id IS NULL AND status = #{Project::STATUS_ACTIVE}",
          :order => 'name')
        @source_project = Project.find(params[:id])
        begin
          @issue_trackers_count = Issue.count(:conditions => {:project_id => @source_project.id}, :group => :tracker)
          @issues_by_tracker = {}
          @issue_trackers_count.keys.each do |tracker|
            @issues_by_tracker[tracker] = Issue.find(:all, :select => :id, :conditions => {:project_id => @source_project.id, :tracker_id => tracker.id})
          end
        rescue
        end
        if request.get?
          @project = Project.copy_from(@source_project)
          if @project
            @project.identifier = Project.next_identifier if Setting.sequential_project_identifiers?
            @project.send(:assign_attributes, params[:project]) if params[:project]
          else
            redirect_to :controller => 'admin', :action => 'projects'
          end
        else
          Mailer.with_deliveries(params[:notifications] == '1') do
            with_suprojects = params[:only] && params[:only].delete('subprojects')

            if with_suprojects
              project_param = params[:project]
              project_param['id'] = @source_project.id.to_s

              projects_attributes = @source_project.descendants.non_templates.collect {|child| {'name' => child.name, 'id' => child.id.to_s}}
              projects_attributes << project_param

              @project, saved_projects, unsaved_projects = @source_project.project_with_subprojects_from_template(params[:project]['parent_id'], projects_attributes, {:only => params[:only], :copying_action => :copying_project})
              unless unsaved_projects.blank?
                errs = []
                unsaved_projects.each do |unsaved_project|
                  errs << l(:notice_failed_create_project_from_template, :errors => unsaved_project.errors.full_messages.join(','))
                end
                flash[:error] = errs.join('<br />').html_safe
              end
            else
              @project = @source_project.project_from_template(params[:project]['parent_id'], params[:project], {:only => params[:only], :copying_action => :copying_project})
            end

            if @project.nil? || !@project.valid?
              flash[:error] = l(:notice_failed_create_project_from_template, :errors => @project.errors.full_messages.join(','))
              call_hook(:controller_projects_copy_after_copy_failed, { :params => params, :source_project => @source_project, :target_project => @project })
              #redirect_to settings_project_path(@project)
            else
              call_hook(:controller_projects_copy_after_copy_successful, { :params => params, :source_project => @source_project, :target_project => @project })
              flash[:notice] = l(:notice_successful_create_project_from_template)
              redirect_to settings_project_path(@project)
            end
          end
        end
      rescue ActiveRecord::RecordNotFound
        # source_project not found
        render_404
      end

      def archive_with_easy_extensions
        if request.post?
          if @project.archive
            flash[:notice] = l(:notice_project_successful_archive)
          else
            flash[:error] = l(:error_can_not_archive_project)
          end
        end
        if params[:admin]
          redirect_to admin_projects_path(:status => params[:status], :name => params[:name])
        else
          redirect_to(:action => 'index')
        end
      end

      def unarchive_with_easy_extensions
        if request.post? && !@project.active?
          if @project.unarchive
            flash[:notice] = l(:notice_project_successful_unarchive)
          else
            flash[:error] = l(:error_can_not_unarchive_project)
          end
        end

        redirect_to admin_projects_path(:status => params[:status], :name => params[:name])
      end

      def close_with_easy_extensions
        @project.close
        redirect_back_or_default project_path(@project)
      end

      def reopen_with_easy_extensions
        @project.reopen
        redirect_back_or_default project_path(@project)
      end

    end

  end

end
EasyExtensions::PatchManager.register_controller_patch 'ProjectsController', 'EasyPatch::ProjectsControllerPatch'
