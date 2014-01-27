class EasyMoneyRatesController < ApplicationController

  before_filter :find_project_by_project_id, :only => [:update_rates, :update_rates_to_subprojects, :easy_money_rate_roles, :easy_money_rate_time_entry_activities, :easy_money_rate_users]
  before_filter :my_authorize, :only => [:update_rates, :update_rates_to_subprojects, :easy_money_rate_roles, :easy_money_rate_time_entry_activities, :easy_money_rate_users]
  before_filter :my_require_admin, :only => [:update_rates, :easy_money_rate_roles, :easy_money_rate_time_entry_activities, :easy_money_rate_users]
  before_filter :require_admin, :only => [:update_rates_to_projects]

  accept_api_auth :easy_money_rate_roles, :easy_money_rate_time_entry_activities, :easy_money_rate_users

  helper :easy_money
  include EasyMoneyHelper

  def update_rates
    project_id = @project.id if @project

    update_rates_core(project_id, params[:valid_from], params[:valid_to], params[:easy_money_rates])

    if request.xhr?
      render :nothing => true
    else
      flash[:notice] = l(:notice_successful_update)

      if @project
        redirect_back_or_default(:controller => 'easy_money_settings', :action => 'project_settings', :project_id => @project)
      else
        redirect_back_or_default(:controller => 'easy_money_settings', :action => 'index')
      end
    end
  end

  def update_rates_to_projects
    update_rates_core(nil, params[:valid_from], params[:valid_to], params[:easy_money_rates])
    Project.non_templates.active.has_module(:easy_money).each do |project|
      update_rates_core(project.id, params[:valid_from], params[:valid_to], params[:easy_money_rates])
    end
    render :nothing => true
  end

  def update_rates_to_subprojects
    update_rates_core(@project.id, params[:valid_from], params[:valid_to], params[:easy_money_rates])
    @project.descendants.active.non_templates.has_module(:easy_money).each do |project|
      update_rates_core(project.id, params[:valid_from], params[:valid_to], params[:easy_money_rates])
    end
    render :nothing => true
  end

  def easy_money_rate_roles
    if request.put? && params[:easy_money_rates]
      update_easy_money_rates_from_api('Role')
    end

    if @project.nil?
      @roles = Role.order(:position).all
    else
      @roles = @project.all_members_roles
    end

    respond_to do |format|
      format.api
    end
  end

  def easy_money_rate_time_entry_activities
    if request.put? && params[:easy_money_rates]
      update_easy_money_rates_from_api('Enumeration')
    end

    if @project.nil?
      @activities = TimeEntryActivity.shared.active
    else
      @activities = @project.activities
    end

    respond_to do |format|
      format.api
    end
  end

  def easy_money_rate_users
    if request.put? && params[:easy_money_rates]
      update_easy_money_rates_from_api('Principal')
    end

    if @project.nil?
      @users = User.active.non_system_flag.sorted
    else
      @users = @project.users.non_system_flag.sorted
    end

    respond_to do |format|
      format.api
    end
  end

  private

  def update_rates_core(project_id, valid_from, valid_to, rates)
    rates.each_pair do |entity_type, entity_rates|
      entity_rates.each_pair do |entity_id, rate_types|
        rate_types.each_pair do |rate_type_id, unit_rate|
          update_easy_money_rate_core(rate_type_id, entity_type, entity_id, project_id, valid_from, valid_to, unit_rate)
        end
      end
    end unless rates.blank?
  end

  def update_easy_money_rate_core(rate_type_id, entity_type, entity_id, project_id, valid_from, valid_to, unit_rate)
    rate = EasyMoneyRate.get_rate(EasyMoneyRateType.find(rate_type_id), entity_type, entity_id, project_id, valid_from, valid_to)
    unit_rate = 0.0 if unit_rate.is_a?(String) && unit_rate.blank?
    if rate.nil?
      EasyMoneyRate.create :project_id => project_id, :rate_type_id => rate_type_id, :entity_type => entity_type, :entity_id => entity_id, :unit_rate => unit_rate, :valid_from => valid_from, :valid_to => valid_to
    else
      rate.unit_rate = unit_rate
      rate.save
    end
  end

  def update_easy_money_rates_from_api(entity_type)
    return if params[:easy_money_rates].nil? || params[:easy_money_rates][:easy_money_rate_type].nil?
    easy_money_rate_types = Array.wrap(params[:easy_money_rates][:easy_money_rate_type])
    easy_money_rate_types.each do |easy_money_rate_type|

      easy_money_rates = Array.wrap(easy_money_rate_type[:easy_money_rate])
      easy_money_rates.each do |easy_money_rate|
        update_easy_money_rate_core(easy_money_rate_type[:id], entity_type, easy_money_rate[:id], @project.nil? ? nil : @project.id, nil, nil, easy_money_rate[:unit_rate])
      end
    end
  end

  def find_project_by_project_id
    @project = Project.find(params[:project_id]) if params[:project_id]
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

end
