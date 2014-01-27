class EasyMoneySettingsController < ApplicationController
  layout 'admin'

  menu_item :easy_money

  before_filter :find_project_by_project_id, :only => [:project_settings, :move_rate_priority, :update_settings, :recalculate, :update_settings_to_subprojects, :easy_money_rate_priorities]
  before_filter :my_authorize, :only => [:project_settings, :move_rate_priority, :update_settings, :recalculate, :easy_money_rate_priorities, :easy_money_rate_roles, :easy_money_rate_time_entry_activities, :easy_money_rate_users]
  before_filter :my_require_admin, :only => [:index, :custom_field_new, :custom_field_edit, :custom_field_destroy, :move_rate_priority, :update_settings, :update_settings_to_projects, :recalculate, :easy_money_rate_priorities, :easy_money_rate_roles, :easy_money_rate_time_entry_activities, :easy_money_rate_users]
  before_filter :set_layout

  accept_api_auth :easy_money_rate_priorities

  helper :easy_money
  include EasyMoneyHelper
  helper :easy_money_settings
  include EasyMoneySettingsHelper
  helper :custom_fields
  include CustomFieldsHelper

  def index
    @custom_fields_by_type = CustomField.where(:type => ['EasyMoneyExpectedExpenseCustomField', 'EasyMoneyExpectedRevenueCustomField', 'EasyMoneyOtherExpenseCustomField', 'EasyMoneyOtherRevenueCustomField']).order(:position).all.group_by {|f| f.class.name }
    @tab = params[:tab] || 'EasyMoneyExpectedExpenseCustomField'
    @different_settings = {}
    @different_settings[:revenues] = EasyMoneySettings.includes(:project).where("#{EasyMoneySettings.table_name}.name = 'revenues_type' AND #{EasyMoneySettings.table_name}.value <> '#{EasyMoneySettings.find_settings_by_name('revenues_type',nil)}' AND #{EasyMoneySettings.table_name}.project_id IS NOT NULL").collect{|revenues| revenues.project.name}.join(', ')
    @different_settings[:expenses] = EasyMoneySettings.includes(:project).where("#{EasyMoneySettings.table_name}.name = 'expenses_type' AND #{EasyMoneySettings.table_name}.value <> '#{EasyMoneySettings.find_settings_by_name('expenses_type',nil)}' AND #{EasyMoneySettings.table_name}.project_id IS NOT NULL").collect{|expenses| expenses.project.name}.join(', ')
  end

  def project_settings
  end

  def move_rate_priority
    @rate_priority = EasyMoneyRatePriority.find(params[:id])
    @rate_priority.update_attributes(params[:easy_money_rate_priority])

    respond_to do |format|
      format.js
    end
  end

  def update_settings
    project = Project.find(params[:project_id]) if params[:project_id]

    update_settings_core(project && project.id)

    flash[:notice] = l(:notice_successful_update)
    if project
      redirect_to :action => 'project_settings', :tab => 'EasyMoneyOtherSettings', :project_id => project
    else
      redirect_to :action => 'index', :tab => 'EasyMoneyOtherSettings'
    end

  end

  def update_settings_to_projects
    update_settings_core(nil)
    Project.active.has_module(:easy_money).each do |project|
      update_settings_core(project.id)
    end
    redirect_to :action => 'index', :tab => 'EasyMoneyOtherSettings'
  end

  def update_settings_to_subprojects
    update_settings_core(@project)
    @project.descendants.active.has_module(:easy_money).each do |project|
      update_settings_core(project.id)
    end
    redirect_to :action => 'index', :tab => 'EasyMoneyOtherSettings'
  end

  def recalculate
    if params[:project_id]
      Project.find(params[:project_id]).self_and_descendants.each{|p| expire_fragment("easy_money_project_overview_project_#{p.id}")}
    else
      Project.non_templates.has_module(:easy_money).each{|p| expire_fragment("easy_money_project_overview_project_#{p.id}")}
    end

    flash[:notice] = l(:notice_easy_money_recalculate)

    if params[:back_url]
      redirect_to params[:back_url]
    else
      redirect_to :back
    end
  end

  def easy_money_rate_priorities
    if request.put? && params[:easy_money_rate_priority] && params[:easy_money_rate_priority][:id]
      params[:easy_money_rate_priority].delete_if { |k| ['project_id', 'rate_type_id', 'entity_type'].include?(k) }
      @rate_priority = EasyMoneyRatePriority.find(params[:easy_money_rate_priority][:id])
      @rate_priority.update_attributes(params[:easy_money_rate_priority])
    end

    respond_to do |format|
      format.api
    end
  end

  private

  def find_project_by_project_id
    @project = Project.find(params[:project_id]) if params[:project_id]
  end

  def set_layout
    unless @project.nil?
      self.class.layout 'base'
    else
      self.class.layout 'admin'
    end
  end

  def my_authorize
    unless @project.nil?
      authorize
    end
  end

  def my_require_admin
    unless @project || User.current.admin?
      authorize
    end
  end

  def update_settings_core(project_id)
    if project_id.blank?
      easy_money_settings = EasyMoneySettings.project_settings_names + EasyMoneySettings.global_settings_names
    else
      easy_money_settings = EasyMoneySettings.project_settings_names
    end
    easy_money_settings.each do |name|
      update_setting_core(project_id, name)
    end unless params[:settings].blank?
  end

  def update_setting_core(project_id, name)
    unless params[:settings].blank?
      s = EasyMoneySettings.find_by_name_and_project_id(name, project_id)
      if s.nil?
        EasyMoneySettings.create :name => name, :project_id => project_id, :value => params[:settings][name]
      else

        case name
        when 'revenues_type'
          delete_all_project_revenues(project_id) if revenues_type_changed?(project_id, params[:settings][name])
        when 'expenses_type'
          delete_all_project_expenses(project_id) if expenses_type_changed?(project_id, params[:settings][name])
        when 'expected_payroll_expense_type'
          #convert_project_expected_payroll_expenses(project_id, params[:settings][:expected_payroll_expense_rate]) if params[:settings][name] == 'hours'
        end

        s.value = params[:settings][name]
        s.save!
      end
    end
  end

  def revenues_type_changed?(project_id, value)
    if project_id
      return Project.find(project_id).easy_money_settings.revenues_type == value ? false : true
    end
  end

  def expenses_type_changed?(project_id, value)
    if project_id
      return Project.find(project_id).easy_money_settings.expenses_type == value ? false : true
    end
  end

  def delete_all_project_revenues(project_id)
    if project_id
      project = Project.find(project_id)
      revenues = Array.new
      revenues << project.expected_revenues
      revenues << project.other_revenues
      revenues.flatten.each{|r| r.destroy}
    end
  end

  def delete_all_project_expenses(project_id)
    if project_id
      project = Project.find(project_id)
      expenses = Array.new
      expenses << project.expected_expenses
      expenses << project.other_expenses
      expenses.flatten.each{|r| r.destroy}
    end
  end

  def convert_project_expected_payroll_expenses(project_id, expected_payroll_expense_rate)
    if project_id
      project = Project.find(project_id)

      if project && (expected_hours = project.expected_hours)
        price = expected_hours.hours.to_f * expected_payroll_expense_rate.to_f

        if expected_payroll_expenses = project.expected_payroll_expenses
          expected_payroll_expenses.price = price
          expected_payroll_expenses.save
        else
          project.expected_payroll_expenses.create(:price => price)
        end
      end
    end
  end

end
