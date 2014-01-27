class EasyQueriesController < ApplicationController

  before_filter :find_optional_project, :only => [:new, :create]
  before_filter :find_optional_project_no_auth, :only => [:filters]
  before_filter :create_query, :only => [:new, :create, :search]
  before_filter :find_query, :except => [:new, :create, :preview, :easy_document_preview, :search, :filters]

  helper :custom_fields
  include CustomFieldsHelper
  helper :entity_attribute
  include EntityAttributeHelper
  helper :easy_query
  include EasyQueryHelper
  helper :sort
  include SortHelper
  helper :attachments
  include AttachmentsHelper

  def new
  	# before_filter :create_query
    render :layout => false if request.xhr?
  end

  def create
    if params[:confirm] && @easy_query.save
      flash[:notice] = l(:notice_successful_create)
      redirect_to params[:back_url].present? && params[:back_url] || {:controller => @easy_query.easy_query_entity_controller, :action => @easy_query.easy_query_entity_action, :project_id => @project, :query_id => @easy_query}
      return
    else
      render :action => 'new'
    end
  end

  def edit
  	# before_filter :create_query
  end

  def update
    @easy_query.filters = {}
    @easy_query.add_filters(params[:fields], params[:operators], params[:values]) if params[:fields]
    @easy_query.attributes = params[:easy_query]
    @easy_query.group_by = params[:group_by]
    @easy_query.project = nil if params[:query_is_for_all]
    @easy_query.visibility = EasyQuery::VISIBILITY_PRIVATE unless User.current.allowed_to?(:manage_public_queries, @project, :global => true) || User.current.admin?
    @easy_query.column_names = nil if params[:default_columns]

    if @easy_query.save
      flash[:notice] = l(:notice_successful_update)
      redirect_to params[:back_url].present? && params[:back_url] || {:controller => @easy_query.easy_query_entity_controller, :action => @easy_query.easy_query_entity_action, :project_id => @project, :query_id => @easy_query}
    else
      render :action => 'edit'
    end
  end

  def destroy
    @easy_query.destroy
    # sort_clear for this query
    session["#{@easy_query.easy_query_entity_controller}_#{@easy_query.easy_query_entity_action}_sort"] = nil
    redirect_back_or_default({:controller => @easy_query.easy_query_entity_controller, :action => @easy_query.easy_query_entity_action, :project_id => @project, :set_filter => 0})
  end

  def preview
    query = params[:easy_query_type].constantize.new(:name => '_') unless params[:easy_query_type].blank?

    if query
      sort_init(query.sort_criteria_init)
      sort_update(query.sortable_columns)
      query.from_params(params[params[:block_name]]) unless params[:block_name].blank?

      add_additional_statement_to_query(query)

      entities = query.prepare_result
      case params[:easy_query_render]
      when 'list'
        render :partial => 'easy_queries/easy_query_entities_list', :locals => {:query => query, :entities => entities, :block_name => params[:block_name], :options => {:disable_sort => true}}
        return
      when 'tree'
        render :partial => 'easy_queries/easy_query_entities_tree', :locals => {:query => query, :entities => entities, :block_name => params[:block_name]}
        return
      end
    end

    render :nothing => true
  end

  def easy_document_preview
    query = params[:easy_query_type].constantize.new(:name => '_') unless params[:easy_query_type].blank?

    if query
      sort_init(query.sort_criteria_init)
      sort_update(query.sortable_columns)
      query.from_params(params[params[:block_name]]) unless params[:block_name].blank?
      documents = query.entities(:include => [:project, :category, :attachments])

      if params[:block_name]
        row_limit = params[params[:block_name]][:row_limit].to_i
        sort_by = params[params[:block_name]][:sort_by]
      end
      documents_count, documents = EasyDocumentQuery.filter_non_restricted_documents(documents, User.current, row_limit || 0, sort_by || '')

      render :partial => 'documents/index', :locals => {:grouped => documents }
    else
      render :nothing => true
    end

  end

  def filters
    if params[:easy_page_zone_module_uuid] && (epmz = EasyPageZoneModule.where({:uuid => params[:easy_page_zone_module_uuid]}).first)
      if epmz.settings.is_a?(Hash)
        settings = epmz.settings
        settings.delete('query_id') if settings['query_type'] == '2'
        params.merge!(settings)
        params[:set_filter] = epmz.settings[:easy_query] ? '1' : '0'
      end
      if epmz.easy_pages_id == EasyPage.page_project_overview.id && epmz.entity_id
        @project = Project.find(epmz.entity_id)
      end
    end

    retrieve_query(params[:type].constantize, :query_param => params[:query_param])


    render :partial => 'easy_queries/filters', :locals => {
      :query => @query,
      :modul_uniq_id => params[:modul_uniq_id],
      :block_name => params[:block_name]
    }
  end

  private

  def create_query
    begin
      @easy_query = params[:type].constantize.new(params[:easy_query]) if params[:type]
    rescue
    end

    if @easy_query
      @easy_query.project = params[:query_is_for_all] ? nil : @project
      @easy_query.from_params(params)
      @easy_query.user = User.current
      @easy_query.visibility = EasyQuery::VISIBILITY_PRIVATE unless User.current.allowed_to?(:manage_public_queries, @project, :global => true) || User.current.admin?
      @easy_query.column_names = nil if params[:default_columns]
    else
      render_404
    end
  end

  def find_query
    @easy_query = EasyQuery.find(params[:id])
    @project = @easy_query.project
    render_403 unless @easy_query.editable_by?(User.current)
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_optional_project(auth=true)
    @project = Project.find(params[:project_id]) if params[:project_id]
    render_403 if auth && !User.current.allowed_to?(:save_queries, @project, :global => true)
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_optional_project_no_auth
    find_optional_project(false)
  end

  def add_additional_statement_to_query(query)
    if query.is_a?(EasyProjectQuery)
      additional_statement = "#{Project.table_name}.easy_is_easy_template=#{query.connection.quoted_false}"
      additional_statement << (' AND ' + Project.visible_condition(User.current))

      if query.additional_statement.blank?
        query.additional_statement = additional_statement
      else
        query.additional_statement << ' AND ' + additional_statement
      end
    end
  end

end
