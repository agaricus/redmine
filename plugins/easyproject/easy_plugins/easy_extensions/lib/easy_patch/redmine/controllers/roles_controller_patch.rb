module EasyPatch
  module RolesControllerPatch

    def self.included(base)
      base.send(:include, InstanceMethods)

      base.class_eval do

        cache_sweeper :role_or_permissions_changed_sweeper

        alias_method_chain :index, :easy_extensions
        alias_method_chain :require_admin, :easy_extensions
        alias_method_chain :require_admin_or_api_request, :easy_extensions
        alias_method_chain :update, :easy_extensions

      end
    end

    module InstanceMethods

      def index_with_easy_extensions
        respond_to do |format|
          format.html {
            @role_pages, @roles = paginate Role.sorted, :per_page => 25

            if request.xhr? && @role_pages.last_page.to_i < params['page'].to_i
              render_404
            else
              render :action => 'index', :layout => false if request.xhr?
            end
          }
          format.api {
            @roles = Role.givable.all
          }
        end
      end

      def require_admin_with_easy_extensions
        require_admin_or_lesser_admin(:roles)
      end

      def require_admin_or_api_request_with_easy_extensions
        require_admin_or_api_request_or_lesser_admin(:roles)
      end

      def update_with_easy_extensions
        respond_to do |format|
          if request.put? and @role.update_attributes(params[:role])
            flash[:notice] = l(:notice_successful_update)
            format.html {redirect_to roles_path}
            format.api {render_api_ok}
          else
            format.html {render :action => 'edit'}
            format.api  { render_validation_errors(@role) }
          end
        end
      end

    end

  end
end
EasyExtensions::PatchManager.register_controller_patch 'RolesController', 'EasyPatch::RolesControllerPatch'
