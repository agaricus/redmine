class EasyMoneyProjectCachesController < ApplicationController

  menu_item :easy_money

  before_filter :authorize_global

  accept_api_auth :index

  helper :easy_query
  include EasyQueryHelper
  helper :entity_attribute
  include EntityAttributeHelper
  helper :easy_money
  include EasyMoneyHelper
  helper :projects
  include ProjectsHelper
  helper :sort
  include SortHelper

  def index
    retrieve_query(EasyMoneyProjectCacheQuery)
    sort_init(@query.sort_criteria.empty? ? [['lft', 'asc']] : @query.sort_criteria)
    sort_update(@query.sortable_columns)

    case params[:format]
    when 'csv', 'pdf', 'ics'
      @limit = Setting.issues_export_limit.to_i
    when 'atom'
      @limit = Setting.feeds_limit.to_i
    when 'xml', 'json'
      @offset, @limit = api_offset_and_limit
    else
      @limit = per_page_option
    end

    @entity_count = @query.entity_count
    @entity_pages = Redmine::Pagination::Paginator.new @entity_count, @limit, params['page']

    if request.xhr? && @entity_pages.last_page.to_i < params['page'].to_i
      render_404
      return false
    end

    @offset ||= @entity_pages.offset
    @entities = @query.prepare_result({:order => sort_clause, :offset => @offset, :limit => @limit} )

    respond_to do |format|
      format.html {
        if request.xhr? && params[:easy_query_q]
          render(:partial => 'easy_queries/easy_query_entities_list', :locals => {:query => @query, :entities => @entities})
        else
          render :layout => !request.xhr?
        end
      }
      format.api
      format.csv {send_data(export_to_csv(@query.prepare_result({:order => sort_clause}), @query), :filename => get_export_filename(:csv, @query, l(:label_easy_money_project_cache)))}
      format.pdf {send_data(export_to_pdf(@query.prepare_result({:order => sort_clause}), @query, :default_title => l(:label_easy_money_project_cache)), :filename => get_export_filename(:pdf, @query, l(:label_easy_money_project_cache)))}
    end
  end

end
