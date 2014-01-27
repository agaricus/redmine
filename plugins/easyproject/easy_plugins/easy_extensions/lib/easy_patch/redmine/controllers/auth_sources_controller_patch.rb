module EasyPatch
  module AuthSourcesControllerPatch

    def self.included(base)
      base.send(:include, InstanceMethods)
      base.class_eval do

        alias_method_chain :destroy, :easy_extensions

      end
    end

    module InstanceMethods

      def destroy_with_easy_extensions
        if @auth_source.users.exists?
          if params[:auth_source_replacement]
            replacement = params[:auth_source_replacement].blank? ? nil : AuthSource.find(params[:auth_source_replacement])
            User.where(:auth_source_id => @auth_source.id).all.each do |user|
              user.auth_source = replacement
              user.save
            end
            @auth_source.destroy
            flash[:notice] = l(:notice_successful_delete)
            redirect_to auth_sources_path
          else
            flash[:error] = l(:error_can_not_delete_auth_source)
            redirect_to :action => 'move_users'
          end
        else
          @auth_source.destroy
          flash[:notice] = l(:notice_successful_delete)
          redirect_to auth_sources_path
        end
      end

      def move_users
        @auth_source = AuthSource.find(params[:id])
        @auth_sources = AuthSource.all(:conditions => ["#{AuthSource.table_name}.id != ?", @auth_source])
      end

    end

  end
end
EasyExtensions::PatchManager.register_controller_patch 'AuthSourcesController', 'EasyPatch::AuthSourcesControllerPatch'
