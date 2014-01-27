class BudgetsheetController < ApplicationController

  before_filter :authorize_global

  helper :sort
  include SortHelper
  helper :issues
  helper :entity_attribute
  include EntityAttributeHelper
  helper :easy_query
  include EasyQueryHelper
  helper :custom_fields
  include CustomFieldsHelper

  def index
    retrieve_query(EasyBudgetSheetQuery)

    @easy_query_name = l(:budgetsheet_title)
    
    if params[:query_by_user] && params[:user_id]
      @query.remove_user_column
      @easy_query_name = User.find(params[:user_id]).name
    end

    sort_init(@query.sort_criteria_init)
    sort_update(@query.sortable_columns)

    limit = per_page_option
    @time_entry_count = @query.entity_count
    @time_entry_pages = Redmine::Pagination::Paginator.new @time_entry_count, limit, params[:page]

    if request.xhr? && @time_entry_pages.last_page.to_i < params['page'].to_i
      render_404
      return false
    end
    offset = @time_entry_pages.offset

    @total_hours = @query.entity_sum("#{TimeEntry.table_name}.hours")

    respond_to do |format|
      format.html {
        @time_entries = @query.prepare_result(:offset => offset, :limit => limit, :order => sort_clause)
        render :action => 'index', :layout => !request.xhr?
      }
      format.csv  {
        send_data(export_to_csv(@query.entities, @query), :filename => get_export_filename(:csv, @query))
      }
      format.pdf  {
        send_data(export_to_pdf(@query.prepare_result(:order => sort_clause), @query, {:hide_sums_in_group_by => true}), :filename => get_export_filename(:pdf, @query))
      }
    end
  end

  private

  def find_project
    @project = Project.find(params[:id])
  end

end
