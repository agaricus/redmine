class EasyMoneyExpectedHoursController < ApplicationController

  menu_item :easy_money

  before_filter :find_easy_money_project
  before_filter :authorize
  before_filter :check_setting_show_expected
  before_filter :check_setting_expected_payroll_expense_type

  helper :easy_money
  include EasyMoneyHelper

  def inline_edit
    respond_to do |format|
      format.js
    end
  end

  def inline_update
    expected_hours = @entity.expected_hours
    if expected_hours
      expected_hours.hours = params[:expected_hours][:hours].to_i
      expected_hours.save
    else
      @entity.create_expected_hours(:hours => params[:expected_hours][:hours].to_i)
    end

    rebuild_expected_payroll_expenses

    respond_to do |format|
      format.js
    end
  end

  private

  def rebuild_expected_payroll_expenses
    expected_payroll_expenses = @entity.expected_payroll_expenses
    if expected_payroll_expenses
      expected_payroll_expenses.price = (@entity.expected_hours.hours * @project.easy_money_settings.expected_payroll_expense_rate.to_i).to_f
      expected_payroll_expenses.save
    else
      @entity.create_expected_payroll_expenses(:price => ( @entity.expected_hours.hours * @project.easy_money_settings.expected_payroll_expense_rate.to_i).to_f)
    end
  end

  def check_setting_show_expected
    render_404 unless @project.easy_money_settings.show_expected?
  end

  def check_setting_expected_payroll_expense_type
    render_404 if @project.easy_money_settings.expected_payroll_expense_type == 'amount'
  end

end
