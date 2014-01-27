class EasyDocumentsController < ApplicationController

  before_filter :find_project_by_project_id, :only => [:select_project]

  helper :attachments
  include AttachmentsHelper
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

  def index
    retrieve_query(EasyDocumentQuery)

    additional_statement = "#{Project.table_name}.easy_is_easy_template=#{@query.connection.quoted_false}"

    if @query.additional_statement.blank?
      @query.additional_statement = additional_statement
    else
      @query.additional_statement << ' AND ' + additional_statement
    end

    @limit = per_page_option
    @document_count = @query.entity_count
    @document_pages = Redmine::Pagination::Paginator.new @document_count, @limit, params[:page]
    offset = @document_pages.offset

    @sort_by = %w(category date title author project).include?(params[:sort_by]) ? params[:sort_by] : 'category'

    documents = @query.entities(:include => [:project, :category, :attachments], :offset => offset, :limit => @limit)

    @query.export_formats.delete_if{|k, v| k != :csv}

    respond_to do |format|
      format.html {
        @document_count, @categories_documents = EasyDocumentQuery.filter_non_restricted_documents(documents, User.current, @limit, @sort_by || '')
      }
      format.csv {
        @document_count, @categories_documents = EasyDocumentQuery.filter_non_restricted_documents(documents, User.current, 0, @sort_by || '')
        send_data(documents_to_csv(@categories_documents.values.flatten, @query), :filename => get_export_filename(:csv, @query))
      }
    end
  end

  def new
    @document = Document.new
    @project = Project.find(params[:project_id]) unless params[:project_id].blank?
    @document = @project.documents.build if @project
    @projects = Project.non_templates.visible.has_module(:documents)
  end

  def select_project
    if @project
      @document = @project.documents.build
      respond_to do |format|
        format.js
      end
    else
      render :nothing => true
    end
  end

  def new_attchments
    @document = Document.find(params[:id])
    respond_to do |format|
      format.js
    end
  end

end
