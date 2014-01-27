class EasyMoneyController < ApplicationController

  menu_item :easy_money

  before_filter :find_easy_money_project, :except => [:index, :project_selector, :projects_to_move, :move_to_project]
  before_filter :authorize_global, :only => [:index]
  before_filter :authorize, :only => [:project_index]

  helper :easy_money
  include EasyMoneyHelper

  def index
    @user = User.current
    render_action_as_easy_page(EasyPage.page_easy_money_projects_overview, nil, nil, url_for(:controller => 'easy_money', :action => 'index'), false, {})
  end

  def index_page_layout
    @user = User.current
    render_action_as_easy_page(EasyPage.page_easy_money_projects_overview, nil, nil, url_for(:controller => 'easy_money', :action => 'index'), true, {})
  end

  def project_index
  end

  def inline_expected_profit
    render :partial => 'easy_money/inline_expected_profit', :locals => { :project => @project, :expected_profit => @entity.easy_money.expected_profit(@project.easy_money_settings.expected_count_price.to_sym) }
  end

  def inline_other_profit
    render :partial => 'easy_money/inline_other_profit', :locals => { :project => @project, :other_profit => @entity.easy_money.other_profit(@project.easy_money_settings.expected_count_price.to_sym, EasyMoneyRateType.active.find(:first, :conditions => {:name => @project.easy_money_settings.expected_rate_type})) }
  end

  def project_selector
    @from_project_id = params[:from_project_id]
    @money_entity_type = params[:money_entity_type]
  end

  def projects_to_move
    @self_only = params[:term].blank?
    @projects = get_projects_to_move(params[:term], params[:term].blank? ? nil : 15)
    respond_to do |format|
      format.api
    end
  end

  def move_to_project
    if params[:from_project_id].present? && params[:to_project_id].present?
      @from_project = Project.find params[:from_project_id]
      @to_project = Project.find params[:to_project_id]

      if params[:ids].nil? || params[:ids].blank?
        flash[:error] = l(:error_easy_money_project_selector_select_values)
        redirect_to :controller => "easy_money_#{params[:money_entity_type]}", :action => 'index', :project_id => @from_project.id
      else
        if User.current.allowed_to?(:easy_money_move, @from_project) && User.current.allowed_to?(:easy_money_move, @to_project)
          case params[:money_entity_type]
          when 'other_expenses'
            money_entites = EasyMoneyOtherExpense.find params[:ids]
            redir_params = {:controller => 'easy_money_other_expenses', :action => 'index', :project_id => @from_project.id}
          when 'other_revenues'
            money_entites = EasyMoneyOtherRevenue.find params[:ids]
            redir_params = {:controller => 'easy_money_other_revenues', :action => 'index', :project_id => @from_project.id}
          when 'expected_expenses'
            money_entites = EasyMoneyExpectedExpense.find params[:ids]
            redir_params = {:controller => 'easy_money_expected_expenses', :action => 'index', :project_id => @from_project.id}
          when 'expected_revenues'
            money_entites = EasyMoneyExpectedRevenue.find params[:ids]
            redir_params = {:controller => 'easy_money_expected_revenues', :action => 'index', :project_id => @from_project.id}
          end
          money_entites.each do |e|
            e.update_attributes({:entity_id => @to_project.id, :entity_type => 'Project'})
          end
          redirect_to redir_params
        else
          render_403
        end
      end
    else
      render_404
    end
  end

  private

  def get_projects_to_move(term = '', limit = nil)
    Project.active.non_templates.has_module(:easy_money).where(["#{Project.allowed_to_condition(User.current, :easy_money_move)} AND #{Project.table_name}.name like ?", "%#{term}%"]).reorder("#{Project.table_name}.lft").limit(limit).all
  end

end
