module EasyPatch
  module DocumentsControllerPatch

    def self.included(base)
      base.send(:include, InstanceMethods)

      base.class_eval do

        before_filter :csv, :only => [:index]

        menu_item :documents

        # cache_sweeper :my_page_others_documents_sweeper

        helper :entity_attribute
        include EntityAttributeHelper
        helper :easy_query
        include EasyQueryHelper
        helper :sort
        include SortHelper
        helper :documents
        include DocumentsHelper
        helper :custom_fields
        include CustomFieldsHelper

        alias_method_chain :index, :easy_extensions
        alias_method_chain :edit, :easy_extensions
        alias_method_chain :add_attachment, :easy_extensions

         def csv
          return true unless request.format == :csv
          query = EasyDocumentQuery.new(:name => '_')
          documents = @project.documents.includes([:attachments, :category]).all.select{|x| x.respond_to?(:active_record_restricted?) ? !x.active_record_restricted?(User.current, :read) : true}

          send_data(documents_to_csv(documents, query), :filename => get_export_filename(:csv, query))
        end

      end
    end

    module InstanceMethods

      def index_with_easy_extensions
        @sort_by = %w(category date title author).include?(params[:sort_by]) ? params[:sort_by] : 'category'

        @document = @project.documents.build


        limit = 3 #per_page_option
        documents = @project.documents.includes(:attachments, :category).order("#{Document.quoted_table_name}.#{Document.connection.quote_column_name 'category_id'} DESC")
        documents = documents.select{|x| x.respond_to?(:active_record_restricted?) ? !x.active_record_restricted?(User.current, :read) : true}

        @document_count = documents.count
        @document_pages = Redmine::Pagination::Paginator.new @document_count, limit, params[:page]
        offset = @document_pages.offset

        count, @grouped = EasyDocumentQuery.filter_non_restricted_documents(documents[offset..-1], User.current, limit, @sort_by || '')

        if request.xhr? && @document_pages.last_page.to_i < params['page'].to_i
          render_404
          return false
        end

        render :layout => false if request.xhr?
      end

      def edit_with_easy_extensions
        @categories = DocumentCategory.active
        @document.safe_attributes = params[:document]
        if request.post? and @document.save
          flash[:notice] = l(:notice_successful_update)
          redirect_to :controller => 'documents', :project_id => @project
        end
      end

      def add_attachment_with_easy_extensions
        attachments = Attachment.attach_files(@document, params[:attachments])
        render_attachment_warning_if_needed(@document)

        files = attachments[:files] + attachments[:new_versions]
        Mailer.attachments_added(files).deliver if attachments.present? && files.present? && Setting.notified_events.include?('document_added')
        redirect_to :controller => 'documents', :project_id => @project
      end

    end

  end

end
EasyExtensions::PatchManager.register_controller_patch 'DocumentsController', 'EasyPatch::DocumentsControllerPatch'
