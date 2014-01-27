module EasyPatch
  module VersionsControllerPatch

    def self.included(base)
      base.send(:include, InstanceMethods)

      base.class_eval do

        before_filter :authorize_global, :only => [:bulk_edit, :bulk_update, :bulk_destroy]
        before_filter :find_optional_project, :only => [:bulk_edit, :bulk_update, :bulk_destroy]

        around_filter :find_project, :only => [:toggle_roadmap_trackers]
        skip_before_filter :authorize, :only => [:toggle_roadmap_trackers, :bulk_edit, :bulk_update, :bulk_destroy]
        skip_before_filter :find_model_object, :only => [:toggle_roadmap_trackers, :bulk_edit, :bulk_update, :bulk_destroy]
        skip_before_filter :find_project_from_association, :only => [:toggle_roadmap_trackers, :bulk_edit, :bulk_update, :bulk_destroy]
        before_filter :find_relations, :only => [:edit, :update]

        helper :issues
        helper :journals
        helper :easy_journal
        helper :entity_attribute
        helper :easy_project_relations
        include EasyProjectRelationsHelper

        alias_method_chain :index, :easy_extensions
        alias_method_chain :new, :easy_extensions
        alias_method_chain :update, :easy_extensions
        alias_method_chain :show, :easy_extensions

        def toggle_roadmap_trackers
          @with_subprojects = params[:with_subprojects].nil? ? Setting.display_subprojects_issues? : (params[:with_subprojects] == '1')
          retrieve_trackers
          retrieve_selected_tracker_ids(@trackers, @trackers.select {|t| t.is_in_roadmap?})

          render :partial => 'versions/trackers', :locals => {:trackers => @trackers, :selected_tracker_ids => @selected_tracker_ids}
        end

        def bulk_edit
          @versions = Version.visible.where(:id => params[:ids])
        end

        def bulk_update
          @versions = Version.visible.where(:id => params[:ids])
          attributes = parse_params_for_bulk_entity_attributes(params[:version])
          errors = Array.new
          @versions.each do |version|
            version.init_journal(User.current)
            version.safe_attributes = attributes
            edw = version.effective_date_was
            if version.save
              version.update_issues_due_dates(edw) if params[:update_database]
            else
              errors << "#{version.name} : #{version.errors.full_messages.join(', ')}"
            end
          end
          if errors.blank?
            flash[:notice] = l(:notice_successful_update)
          else
            flash[:error] = l(:error_bulk_update_save, :count => @versions.count - errors.size) + '<br />'.html_safe + errors.join('<br />').html_safe
          end

          redirect_back_or_default :controller => 'projects', :action => 'settings', :tab => 'versions', :id => @project
        end

        def bulk_destroy
          Version.destroy_all(:id => params[:ids])
          flash[:notice] = l(:notice_successful_delete)

          redirect_back_or_default :controller => 'projects', :action => 'settings', :tab => 'versions', :id => @project
        end

        private

        def find_relations
          @relations = @version.relations.select {|r| r.other_version(@version) && r.other_version(@version).visible? }
        end

        def retrieve_trackers
          if @with_subprojects
            @trackers = @project.self_and_descendants.non_templates.collect(&:trackers).flatten.uniq.sort_by(&:position)
          else
            @trackers = @project.trackers.find(:all, :order => 'position')
          end
        end

      end
    end

    module InstanceMethods

      def index_with_easy_extensions
        respond_to do |format|
          format.html {
            @with_subprojects = params[:with_subprojects].nil? ? Setting.display_subprojects_issues? : (params[:with_subprojects] == '1')
            @with_non_shared_versions = params[:with_non_shared_versions].nil? ? false : (params[:with_non_shared_versions] == '1')
            retrieve_trackers
            retrieve_selected_tracker_ids(@trackers, @trackers.select {|t| t.is_in_roadmap?})
            @closed_issues = params[:closed_issues].nil? ? false : (params[:closed_issues] == "1")

            if @project.easy_is_easy_template?
              project_ids = @with_subprojects ? @project.self_and_descendants.templates.pluck(:id) : [@project.id]
            else
              project_ids = @with_subprojects ? @project.self_and_descendants.non_templates.pluck(:id) : [@project.id]
            end

            @versions = @project.shared_versions.sort || []
            @versions += @project.rolled_up_versions.visible if @with_subprojects
            @versions = @versions.uniq.sort
            unless params[:completed]
              @completed_versions = @versions.select {|version| version.closed? || version.completed? }
              @versions -= @completed_versions
            end
            @versions.reject! {|version| version.closed? || version.completed? } unless params[:completed]
            @versions.reject! {|version| version.sharing == 'none' && version.project != @project } unless @with_non_shared_versions

            @issues_by_version = {}

            if @selected_tracker_ids.any? && @versions.any?
              scope = Issue.visible
              scope = scope.open unless @closed_issues
              scope = scope.includes(:project, :tracker, :priority).
                preload(:status, :fixed_version).
                where(:tracker_id => @selected_tracker_ids, :project_id => project_ids, :fixed_version_id => @versions.map(&:id)).
                order("#{Project.table_name}.lft, #{Tracker.table_name}.position, #{IssuePriority.table_name}.position DESC, #{Issue.table_name}.due_date")
              @issues_by_version = scope.group_by(&:fixed_version)
            end
            @versions.reject! {|version| !project_ids.include?(version.project_id) && @issues_by_version[version].blank?}
          }
          format.api {
            @versions = @project.shared_versions.all
          }
        end
      end

      def new_with_easy_extensions
        @version = @project.versions.build
        @version.safe_attributes = params[:version]

        respond_to do |format|
          format.html {render :layout => !request.xhr?}
          format.js
        end
      end

      def update_with_easy_extensions
        if request.put? && params[:version]
          attributes = params[:version].dup
          attributes.delete('sharing') unless @version.allowed_sharings.include?(attributes['sharing'])
          @version.init_journal(User.current)
          @version.safe_attributes = attributes
          if @version.valid?
            edw = @version.effective_date_was
            @version.save!
            @version.update_issues_due_dates(edw) if params[:update_database]

            flash[:notice] = l(:notice_successful_update)
            redirect_back_or_default :controller => 'projects', :action => 'settings', :tab => 'versions', :id => @project
          else
            respond_to do |format|
              format.html { render :action => 'edit' }
              format.api { render_api_ok }
            end
          end
        end
      end

      def show_with_easy_extensions
        respond_to do |format|
          format.html {
            @journals = @version.journals.includes(:user, :details).reorder("#{Journal.table_name}.id ASC").all
            @journals.each_with_index {|j,i| j.indice = i+1}
            @journals.reject!(&:private_notes?) unless User.current.allowed_to?(:view_private_notes, @version.project)
            @journals.reverse! if User.current.wants_comments_in_reverse_order?

            @issues = @version.fixed_issues.visible.includes([:project, :status, :tracker, :priority]).order(EasySetting.value('issue_default_sorting_string_long')).all
          }
          format.api
        end
      end
    end
  end
end
EasyExtensions::PatchManager.register_controller_patch 'VersionsController', 'EasyPatch::VersionsControllerPatch'
