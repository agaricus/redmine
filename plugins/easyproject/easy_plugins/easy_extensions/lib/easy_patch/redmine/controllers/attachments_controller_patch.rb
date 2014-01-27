module EasyPatch
  module AttachmentsControllerPatch

    def self.included(base)

      base.class_eval do
        base.send(:include, InstanceMethods)

        before_filter :find_project, :except => [:upload, :destroy_version, :revert_to_version]
        before_filter :file_readable, :read_authorize, :only => [:show, :download, :thumbnail]
        before_filter :delete_authorize, :only => :destroy
        before_filter :authorize_global, :only => :upload
        before_filter :mark_as_read, :only => [:show, :download]

        #        cache_sweeper :my_page_others_documents_sweeper

        alias_method_chain :find_project, :easy_extensions
        alias_method_chain :destroy, :easy_extensions

        # Destroy version of attachment
        def destroy_version
          av = Attachment::Version.find(params[:id])
          @attachment = av.attachment
          if @attachment.versions.count <= 1 && @attachment.container
            if @attachment.container.respond_to?(:init_journal)
              @attachment.container.init_journal(User.current)
            end
            @attachment.container.attachments.delete(@attachment)
          end
          # Make sure association callbacks are called
          av.destroy
          flash[:notice] = l(:notice_successful_delete)
          redirect_to :back
        end

        # Revert attachment version to select version
        def revert_to_version
          if Attachment.find(params[:id]).revert_to!(params[:version_num].to_i)
            flash[:notice] = l('attachments.revert_to.successfully', :version => params[:version_num])
          else
            flash[:error] = l('attachments.revert_to.failed', :version => params[:version_num], :current_v => @attachment.version)
          end
          redirect_to :back
        end

        private

        def mark_as_read
          @attachment.mark_as_read(User.current) if @attachment
        end

      end

    end

    module InstanceMethods

      def destroy_with_easy_extensions
        if @attachment.container.respond_to?(:init_journal)
          @attachment.container.init_journal(User.current)
        end
        if @attachment.container
          # Make sure association callbacks are called
          @attachment.container.attachments.delete(@attachment)
        else
          @attachment.destroy
        end

        respond_to do |format|
          format.html { redirect_to_referer_or(@project.nil? ? home_path : project_path(@project)) }
          format.js
        end
      end

      private

      def find_project_with_easy_extensions
        if params[:version]
          @attachment = Attachment::Version.find(params[:id])
        else
          @attachment = Attachment.find(params[:id])
        end
        # Show 404 if the filename in the url is wrong
        raise ActiveRecord::RecordNotFound if params[:filename] && params[:filename] != @attachment.filename
        @project = @attachment.project
      rescue ActiveRecord::RecordNotFound
        render_404
      end
    end

  end

end
EasyExtensions::PatchManager.register_controller_patch 'AttachmentsController', 'EasyPatch::AttachmentsControllerPatch'
