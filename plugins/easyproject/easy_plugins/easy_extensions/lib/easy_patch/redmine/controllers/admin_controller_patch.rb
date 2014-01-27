module EasyPatch
  module AdminControllerPatch

    def self.included(base)
      base.send(:include, InstanceMethods)
      base.class_eval do

        before_filter :find_projects, :only => [:bulk_destroy, :bulk_archive, :bulk_close, :bulk_reopen, :bulk_unarchive]

        helper :projects, :easy_query, :entity_attribute
        include ProjectsHelper

        alias_method_chain :require_admin, :easy_extensions
        alias_method_chain :projects, :easy_extensions
        alias_method_chain :plugins, :easy_extensions

        def bulk_destroy
          @projects.destroy_all

          redirect_to(url_for(:controller => 'admin', :action => 'projects', :status => params[:status]))
        end

        def bulk_archive
          errors = []
          @projects.each do |project|
            unless project.archive
              flash[:error] << "#{project.name} - #{l(:error_can_not_archive_project)}"
            end
          end
          flash[:error] = errors if errors.any?
          redirect_to(url_for(:controller => 'admin', :action => 'projects', :status => params[:status]))
        end

        def bulk_close
          @projects.each do |project|
            project.close if project.active?
          end
          redirect_to(url_for(:controller => 'admin', :action => 'projects', :status => params[:status]))
        end

        def bulk_reopen
          @projects.each do |project|
            project.reopen if project.status == Project::STATUS_CLOSED
          end
          redirect_to(url_for(:controller => 'admin', :action => 'projects', :status => params[:status]))
        end

        def bulk_unarchive
          @projects.each do |project|
            project.unarchive if !project.active?
          end
          redirect_to(url_for(:controller => 'admin', :action => 'projects', :status => params[:status]))
        end

        private

        def find_projects
          @projects = Project.where(:id => params[:ids])
        end

      end
    end

    module InstanceMethods

      def plugins_with_easy_extensions
        @plugins = Redmine::Plugin.all(:only_visible => true).sort_by{|p| p.name.is_a?(Symbol) ? l(p.name) : p.name }
      end

      def projects_with_easy_extensions
        @query = EasyProjectQuery.new(:name => l(:label_project_plural))

        @query.additional_statement = "#{Project.table_name}.easy_is_easy_template=#{@query.connection.quoted_false}"
        if params[:name]
          pattern = "%#{params[:name].to_s.strip.downcase}%"
          @query.additional_statement << " AND (LOWER(#{Project.table_name}.identifier) LIKE '#{pattern}' OR LOWER(#{Project.table_name}.name) LIKE '#{pattern}')"
        end

        @status = params[:status] || Project::STATUS_ACTIVE.to_s
        @query.filters = {'status' => {:operator => '=', :values => [@status]}} if @status.present?
        @query.user = User.current

        @entity_count = @query.entity_count
        @collapse = !request.xhr?

        sort_init(@query.sort_criteria_init)

        sort_update({'lft' => "#{Project.table_name}.lft"}.merge(@query.sortable_columns))

        if !params[:root_id]
          @entity_count = @query.entity_count
          @limit = per_page_option
          @project_pages = Redmine::Pagination::Paginator.new @entity_count, @limit, params['page']
          @offset = params[:offset].blank? ? @project_pages.offset : params[:offset].to_i
          if request.xhr? && @offset >= @entity_count
            render_404
            return false
          end
          @children_count, @projects = @query.roots(:offset => @offset, :limit => @limit)
        else
          root = Project.find(params[:root_id])
          @query.add_additional_statement "#{Project.table_name}.id != #{params[:root_id]}"
          @query.add_additional_statement "#{Project.table_name}.lft > #{root.lft}"
          @query.add_additional_statement "#{Project.table_name}.rgt < #{root.rgt}"
          @projects = @query.entities(:order => sort_clause, :offset => @offset, :limit => @limit)
          add_non_filtered_projects(:exclude_roots => true)
        end

        render :action => 'projects', :layout => false if request.xhr?
      end

      def require_admin_with_easy_extensions
        require_admin_or_lesser_admin
      end

    end

  end

end
EasyExtensions::PatchManager.register_controller_patch 'AdminController', 'EasyPatch::AdminControllerPatch'
