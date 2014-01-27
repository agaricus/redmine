module EasyPatch
  module EnumerationsControllerPatch

    def self.included(base)
      base.send(:include, InstanceMethods)

      base.class_eval do

        alias_method_chain :create, :easy_extensions
        alias_method_chain :update, :easy_extensions

      end
    end

    module InstanceMethods

      def create_with_easy_extensions
        @enumeration = params[:enumeration][:type].constantize.new((params[:enumeration]))
        if @enumeration.save
          call_hook(:controller_enumerations_create_after_save, { :enumeration => @enumeration })
          flash[:notice] = l(:notice_successful_create)
          redirect_back_or_default enumerations_path
        else
          render :action => 'new'
        end
      end

      def update_with_easy_extensions
        @enumeration = Enumeration.find(params[:id])
        @enumeration.type = params[:enumeration][:type] if params[:enumeration][:type]
        respond_to do |format|
          if @enumeration.update_attributes(params[:enumeration])
            call_hook(:controller_enumerations_edit_after_save, { :enumeration => @enumeration })

            format.html {
              flash[:notice] = l(:notice_successful_update)
              redirect_back_or_default enumerations_path
            }
            format.api {render_api_ok}
          else
            format.html {render :action => 'edit'}
            format.api  { render_validation_errors(@enumeration) }
          end
        end
      end

    end

  end

end
EasyExtensions::PatchManager.register_controller_patch 'EnumerationsController', 'EasyPatch::EnumerationsControllerPatch'
