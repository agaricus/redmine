class EasyMoneyExpectedPayrollExpensesController < ApplicationController

  menu_item :easy_money

  before_filter :find_easy_money_project
  before_filter :authorize
  before_filter :check_setting_show_expected
  before_filter :check_setting_expected_payroll_expense_type, :except => [:inline_expected_payroll_expenses]

  helper :easy_money
  include EasyMoneyHelper

  def inline_edit
    respond_to do |format|
      format.js
    end
  end

  def inline_update
    expected_payroll_expenses = @entity.expected_payroll_expenses
    if expected_payroll_expenses
      expected_payroll_expenses.price = params[:expected_payroll_expenses][:price].to_f
      expected_payroll_expenses.save
    else
      @entity.create_expected_payroll_expenses(:price => params[:expected_payroll_expenses][:price].to_f)
    end

    respond_to do |format|
      format.js
    end
  end

  def inline_expected_payroll_expenses
    render :partial => 'easy_money_expected_payroll_expenses/inline_expected_payroll_expenses', :locals => {:project => @project, :sum_expected_payroll_expenses => @entity.easy_money.sum_expected_payroll_expenses }
  end

  private

  def check_setting_show_expected
    render_404 unless @project.easy_money_settings.show_expected?
  end

  def check_setting_expected_payroll_expense_type
    render_404 if @project.easy_money_settings.expected_payroll_expense_type == 'hours'
  end

end
