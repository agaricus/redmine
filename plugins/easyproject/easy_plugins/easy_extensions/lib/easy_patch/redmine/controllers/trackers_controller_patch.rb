module EasyPatch
  module TrackersControllerPatch

    def self.included(base)
      base.send(:include, InstanceMethods)
      base.class_eval do

        alias_method_chain :destroy, :easy_extensions
        alias_method_chain :index, :easy_extensions
        alias_method_chain :require_admin, :easy_extensions
        alias_method_chain :require_admin_or_api_request, :easy_extensions
        alias_method_chain :update, :easy_extensions

        def move_issues
          @tracker = Tracker.find(params[:id])
          @trackers = Tracker.find(:all, :conditions => ["#{Tracker.table_name}.id != ?", @tracker.id])
          if request.post?
            unless params[:tracker_to_id].blank? || params[:tracker_to_id] == @tracker.id.to_s
              @tracker_to = Tracker.find(params[:tracker_to_id])
              @tracker.move_issues(@tracker_to, Hash[(params[:custom_field_map] || {}).map{|k,v| [k.to_i, v.blank? ? nil : v.to_i]}])
              @tracker.reload
              unless @tracker.issues.empty?
                flash[:error] = l(:error_can_not_delete_tracker)
                redirect_to tracker_move_issues_path(@tracker)
              else
                @tracker.destroy
                redirect_to :action => 'index'
              end
            end
          end
        end

        def custom_field_mapping
          begin
            @tracker = Tracker.find(params[:id], :include => [:custom_fields])
            @tracker_to = Tracker.find(params[:tracker_to_id], :include => [:custom_fields])
          rescue ActiveRecord::RecordNotFound
            render_404
            return
          end
          @custom_field_data = @tracker.custom_field_mapping_data(@tracker_to)
          render :action => 'custom_field_mapping', :layout => false if request.xhr?
        end

      end
    end

    module InstanceMethods

      def index_with_easy_extensions
        respond_to do |format|
          format.html {
            @tracker_pages, @trackers = paginate Tracker.sorted, :per_page => 25

            if request.xhr? && @tracker_pages.last_page.to_i < params['page'].to_i
              render_404
            else
              render :action => "index", :layout => false if request.xhr?
            end
          }
          format.api {
            @trackers = Tracker.sorted.all
          }
        end
      end

      def destroy_with_easy_extensions
        @tracker = Tracker.find(params[:id])
        unless @tracker.issues.empty?
          flash[:error] = l(:error_can_not_delete_tracker)
          if Tracker.count < 2
            redirect_to :action => 'index'
          else
            redirect_to tracker_move_issues_path(@tracker)
          end
        else
          @tracker.destroy
          redirect_to trackers_path
        end
      end

      def update_with_easy_extensions
        @tracker = Tracker.find(params[:id])
        respond_to do |format|
          if @tracker.update_attributes(params[:tracker])
            flash[:notice] = l(:notice_successful_update)
            format.html {redirect_to trackers_path}
            format.api {render_api_ok}
          else
            edit
            format.html {render :action => 'edit'}
            format.api  {render_validation_errors(@tracker)}
          end
        end
      end

      def require_admin_with_easy_extensions
        require_admin_or_lesser_admin(:trackers)
      end

      def require_admin_or_api_request_with_easy_extensions
        require_admin_or_api_request_or_lesser_admin(:trackers)
      end

    end

  end

end
EasyExtensions::PatchManager.register_controller_patch 'TrackersController', 'EasyPatch::TrackersControllerPatch'
