class EasyMoneyQueriesController < ApplicationController

  menu_item :easy_money

  before_filter :authorize_global

  helper :easy_query
  include EasyQueryHelper
  helper :easy_money
  include EasyMoneyHelper
  helper :custom_fields
  include CustomFieldsHelper
  helper :sort
  include SortHelper
  helper :entity_attribute
  include EntityAttributeHelper

  def easy_money_expected_expense
    retrieve_query(EasyMoneyExpectedExpenseQuery)
    sort_init(@query.sort_criteria.empty? ? [["#{EasyMoneyExpectedExpense.table_name}.spent_on", 'desc']] : @query.sort_criteria)
    sort_update(@query.sortable_columns)

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
      format.csv {send_data(export_to_csv(@query.prepare_result({:order => sort_clause}), @query), :filename => get_export_filename(:csv, @query, l(:label_easy_money_expected_expenses)))}
      format.pdf {send_data(export_to_pdf(@query.prepare_result({:order => sort_clause}), @query, :default_title => l(:label_easy_money_expected_expenses)), :filename => get_export_filename(:pdf, @query, l(:label_easy_money_expected_expenses)))}
    end
  end

  def easy_money_expected_expense_context_menu
    render :layout => false
  end

  def easy_money_expected_revenue
    retrieve_query(EasyMoneyExpectedRevenueQuery)
    sort_init(@query.sort_criteria.empty? ? [["#{EasyMoneyExpectedRevenue.table_name}.spent_on", 'desc']] : @query.sort_criteria)
    sort_update(@query.sortable_columns)

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
      format.csv {send_data(export_to_csv(@query.prepare_result({:order => sort_clause}), @query), :filename => get_export_filename(:csv, @query, l(:label_easy_money_expected_revenues)))}
      format.pdf {send_data(export_to_pdf(@query.prepare_result({:order => sort_clause}), @query, :default_title => l(:label_easy_money_expected_revenues)), :filename => get_export_filename(:pdf, @query, l(:label_easy_money_expected_revenues)))}
    end
  end

  def easy_money_expected_revenue_context_menu
    render :layout => false
  end

  def easy_money_other_expense
    retrieve_query(EasyMoneyOtherExpenseQuery)
    sort_init(@query.sort_criteria.empty? ? [["#{EasyMoneyOtherExpense.table_name}.spent_on", 'desc']] : @query.sort_criteria)
    sort_update(@query.sortable_columns)

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
      format.csv {send_data(export_to_csv(@query.prepare_result({:order => sort_clause}), @query), :filename => get_export_filename(:csv, @query, l(:label_easy_money_other_expenses)))}
      format.pdf {send_data(export_to_pdf(@query.prepare_result({:order => sort_clause}), @query, :default_title => l(:label_easy_money_other_expenses)), :filename => get_export_filename(:pdf, @query, l(:label_easy_money_other_expenses)))}
    end
  end

  def easy_money_other_expense_context_menu
    render :layout => false
  end

  def easy_money_other_revenue
    retrieve_query(EasyMoneyOtherRevenueQuery)
    sort_init(@query.sort_criteria.empty? ? [["#{EasyMoneyOtherRevenue.table_name}.spent_on", 'desc']] : @query.sort_criteria)
    sort_update(@query.sortable_columns)

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
      format.csv {send_data(export_to_csv(@query.prepare_result({:order => sort_clause}), @query), :filename => get_export_filename(:csv, @query, l(:label_easy_money_other_revenues)))}
      format.pdf {send_data(export_to_pdf(@query.prepare_result({:order => sort_clause}), @query, :default_title => l(:label_easy_money_other_revenues)), :filename => get_export_filename(:pdf, @query, l(:label_easy_money_other_revenues)))}
    end
  end

  def easy_money_other_revenue_context_menu
    render :layout => false
  end

end
