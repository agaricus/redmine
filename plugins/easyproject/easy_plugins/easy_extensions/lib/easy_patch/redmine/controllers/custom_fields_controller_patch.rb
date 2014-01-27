module EasyPatch
  module CustomFieldsControllerPatch

    def self.included(base)
      base.send(:include, InstanceMethods)
      base.class_eval do

        helper :custom_fields
        include CustomFieldsHelper

        alias_method_chain :index, :easy_extensions
        alias_method_chain :create, :easy_extensions
        alias_method_chain :destroy, :easy_extensions
        alias_method_chain :update, :easy_extensions
        alias_method_chain :build_new_custom_field, :easy_extensions
        alias_method_chain :find_custom_field, :easy_extensions

        def reload_lookup_settings
          if params[:id]
            @custom_field = CustomField.find(params[:id])
            @custom_field.attributes = params[:custom_field]
          elsif params[:type]
            @custom_field = begin
              if params[:type].to_s.match(/.+CustomField$/)
                params[:type].to_s.constantize.new(params[:custom_field])
              end
            rescue
            end
          end

          if @custom_field
            @custom_field.settings ||= {}
          else
            render :nothing => true
          end
        end

        def toggle_disable
          @custom_field = CustomField.unscoped.find(params[:id])

          respond_to do |format|
            format.html {
              if @custom_field.non_deletable
                @custom_field.update_attributes( :disabled => !@custom_field.disabled )
                if @custom_field.disabled
                  flash[:notice] = l(:notice_easy_custom_field_disabled)
                else
                  flash[:notice] = l(:notice_easy_custom_field_enabled)
                end
              else
                flash[:error] = l(:error_easy_custom_field_disable_deletable)
              end
              redirect_to :back
            }
          end

        end

      end
    end

    module InstanceMethods

      def index_with_easy_extensions
        CustomField.unscoped do
          index_without_easy_extensions
        end
      end

      def create_with_easy_extensions
        @custom_field.default_value = params[:custom_field][:default_value] if params[:custom_field] && params[:custom_field][:default_value]
        if @custom_field.save
          flash[:notice] = l(:notice_successful_create)
          call_hook(:controller_custom_fields_new_after_save, :params => params, :custom_field => @custom_field)
          redirect_back_or_default custom_fields_path(:tab => @custom_field.class.name)
        else
          render :action => 'new'
        end
      end

      def update_with_easy_extensions
        respond_to do |format|
          if @custom_field.update_attributes(params[:custom_field])
            flash[:notice] = l(:notice_successful_update)
            call_hook(:controller_custom_fields_edit_after_save, :params => params, :custom_field => @custom_field)
            format.html {redirect_back_or_default custom_fields_path(:tab => @custom_field.class.name)}
            format.api {render_api_ok}
          else
            format.html {render :action => 'edit'}
            format.api  { render_validation_errors(@custom_field) }
          end
        end
      end

      def destroy_with_easy_extensions
        unless @custom_field.non_deletable?
          begin
            @custom_field.destroy
            flash[:notice] = l(:notice_successful_delete)
          rescue
            flash[:error] = l(:error_can_not_delete_custom_field)
          end
          redirect_back_or_default custom_fields_path(:tab => @custom_field.class.name)
        else
          flash[:error] = l(:error_can_not_delete_custom_field)
          redirect_back_or_default(:action => 'index')
        end
      end

      def build_new_custom_field_with_easy_extensions
        build_new_custom_field_without_easy_extensions
        @custom_field.field_format = 'string' if @custom_field && @custom_field.field_format.blank?
      end

      def find_custom_field_with_easy_extensions
        CustomField.unscoped do
          find_custom_field_without_easy_extensions
        end
      end

    end

  end

end
EasyExtensions::PatchManager.register_controller_patch 'CustomFieldsController', 'EasyPatch::CustomFieldsControllerPatch'
