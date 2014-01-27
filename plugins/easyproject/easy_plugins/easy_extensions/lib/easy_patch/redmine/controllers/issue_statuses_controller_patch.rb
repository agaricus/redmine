module EasyPatch
  module IssueStatusesControllerPatch

    def self.included(base)
      base.send(:include, InstanceMethods)
      base.class_eval do

        alias_method_chain :require_admin, :easy_extensions
        alias_method_chain :require_admin_or_api_request, :easy_extensions
        alias_method_chain :update, :easy_extensions

      end
    end

    module InstanceMethods

      def require_admin_with_easy_extensions
        require_admin_or_lesser_admin(:issue_statuses)
      end

      def require_admin_or_api_request_with_easy_extensions
        require_admin_or_api_request_or_lesser_admin(:issue_statuses)
      end

      def update_with_easy_extensions
        @issue_status = IssueStatus.find(params[:id])
        respond_to do |format|
          if @issue_status.update_attributes(params[:issue_status])
            flash[:notice] = l(:notice_successful_update)
            format.html {redirect_to issue_statuses_path}
            format.api {render_api_ok}
          else
            format.html {render :action => 'edit'}
            format.api  { render_validation_errors(@issue_status) }
          end
        end
      end

    end

  end

end
EasyExtensions::PatchManager.register_controller_patch 'IssueStatusesController', 'EasyPatch::IssueStatusesControllerPatch'
