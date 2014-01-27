class EasyVersionsController < ApplicationController

  before_filter :authorize_global

  helper :entity_attribute
  include EntityAttributeHelper
  helper :easy_query
  include EasyQueryHelper
  helper :sort
  include SortHelper
  helper :custom_fields
  include CustomFieldsHelper
  helper :versions
  include VersionsHelper
  helper :easy_version_relations
  include EasyVersionRelationsHelper
  helper :projects
  include ProjectsHelper

  def index
    retrieve_query(EasyVersionQuery)

    sort_init(@query.sort_criteria_init)
    sort_update(@query.sortable_columns)
    @query.easy_query_entity_controller = 'easy_versions'
    respond_to do |format|
      format.html {
        limit = per_page_option
        @entity_count = @query.entity_count
        @entity_pages = Redmine::Pagination::Paginator.new @entity_count, limit, params['page']

        if request.xhr? && @entity_pages.last_page.to_i < params['page'].to_i
          render_404
          return false
        end

        @entities = @query.prepare_result({:order => sort_clause, :offset => @entity_pages.offset, :limit => limit} )
      }
      format.csv {send_data(export_to_csv(@query.prepare_result({:order => sort_clause}), @query), :filename => get_export_filename(:csv, @query))}
      format.pdf {send_data(export_to_pdf(@query.prepare_result({:order => sort_clause}), @query), :filename => get_export_filename(:pdf, @query))}
    end
  end

  def new
    @version = Version.new
    @project = Project.find(params[:project_id]) if params[:project_id]
    if @project
      redirect_to(new_project_version_path(@project))
    else
      @projects = Project.visible.non_templates unless request.xhr?
      render :layout => !request.xhr?
    end
  end

  def create
    @version = Version.new
    attributes = params[:version].dup
    attributes.delete('sharing') unless attributes.nil? || @version.allowed_sharings.include?(attributes['sharing'])
    @version.safe_attributes = attributes

    if @version.save
      flash[:notice] = l(:notice_successful_create)
      redirect_back_or_default :action => 'index'
    else
      render :action => 'new'
    end
  end
end
