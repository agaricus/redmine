class EasyMoneyCashFlowHistoryController < ApplicationController
  menu_item :easy_money

  before_filter :authorize_global, :only => [:index]

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
    retrieve_query(EasyMoneyCashFlowQuery)
    sort_init(@query.sort_criteria.empty? ? [['lft', 'asc']] : @query.sort_criteria)
    sort_update(@query.sortable_columns)

    @expenses_controller = 'easy_money_other_expenses'
    @revenues_controller = 'easy_money_other_revenues'
    @from_date = begin; Date.parse(params[:from_date]); rescue; nil; end unless params[:from_date].blank?
    @from_date ||= Date.today.beginning_of_month - 1.year
    @to_date ||= @from_date.end_of_month + 1.year

    if params[:price_type] == 'price2'
      @price_type = :price2
    else
      @price_type = :price1
    end

    @result = @query.entities(:order => "#{Project.table_name}.lft").collect do |project|
      [
        project,
        project.easy_money.other_expenses_scope(:only_self => true).where(['spent_on BETWEEN ? AND ?', @from_date, @to_date]).group([:tyear, :tmonth]).order([:tyear, :tmonth]).sum(@price_type),
        project.easy_money.other_revenues_scope(:only_self => true).where(['spent_on BETWEEN ? AND ?', @from_date, @to_date]).group([:tyear, :tmonth]).order([:tyear, :tmonth]).sum(@price_type)
      ]
    end

    @sums = 0.upto(11).inject({}) do |total_sum, month_shift|
      current_date = @from_date + month_shift.month
      current_key = [current_date.year, current_date.month]

      sum = @result.inject(0.0) do |memo, x|
        project, expenses, revenues = x
        memo += ((revenues[current_key] || 0.0) - (expenses[current_key] || 0.0))
        memo
      end

      total_sum[current_key] = sum
      total_sum
    end

    respond_to do |format|
      format.html
#      format.api
#      format.csv {send_data(export_to_csv(@query.prepare_result({:order => "#{Project.table_name}.lft"}), @query), :filename => get_export_filename(:csv, @query, l(:label_easy_money_cash_flow_history)))}
#      format.pdf {send_data(export_to_pdf(@query.prepare_result({:order => "#{Project.table_name}.lft"}), @query, :default_title => l(:label_easy_money_cash_flow_history)), :filename => get_export_filename(:pdf, @query, l(:label_easy_money_cash_flow_history)))}
    end
  end

end
