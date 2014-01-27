class EasyMoneyExpectedRevenuesController < ApplicationController

  menu_item :easy_money

  before_filter :find_easy_money_object, :only => [:show, :edit, :update, :destroy]
  before_filter :find_easy_money_project
  before_filter :check_for_project, :only => [:new, :create, :edit, :update]
  before_filter :authorize_global
  before_filter :check_setting_show_expected
  before_filter :check_setting_revenues_type, :only => [:new, :create]
  before_filter :add_price2, :only => [:create, :update]
  before_filter :price_validation, :only => [:create, :update]
  before_filter :set_show_checkbox, :only => [:index]

  accept_api_auth :index, :show, :create, :update, :destroy

  helper :easy_query
  include EasyQueryHelper
  helper :entity_attribute
  include EntityAttributeHelper
  helper :easy_money
  include EasyMoneyHelper
  helper :attachments
  include AttachmentsHelper
  helper :custom_fields
  include CustomFieldsHelper
  helper :projects
  include ProjectsHelper
  helper :sort
  include SortHelper

  def index
    retrieve_query(EasyMoneyExpectedRevenueQuery)
    sort_init(@query.sort_criteria.empty? ? [["#{EasyMoneyExpectedRevenue.table_name}.spent_on", 'desc']] : @query.sort_criteria)
    sort_update(@query.sortable_columns)

    @money_entity_type = 'expected_revenues'

    @query.entity_to_statement = @entity if @entity

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
      format.csv {send_data(export_to_csv(@query.prepare_result({:order => sort_clause}), @query), :filename => get_export_filename(:csv, @query, l(:label_easy_money_expected_revenues)))}
      format.pdf {send_data(export_to_pdf(@query.prepare_result({:order => sort_clause}), @query, :default_title => l(:label_easy_money_expected_revenues)), :filename => get_export_filename(:pdf, @query, l(:label_easy_money_expected_revenues)))}
    end
  end

  def show
    respond_to do |format|
      format.html
      format.api
    end
  end

  def new
    @easy_money_object = EasyMoneyExpectedRevenue.new
    @easy_money_object.safe_attributes = params[:easy_money] if params[:easy_money]
    @easy_money_object.spent_on ||= Date.today

    respond_to do |format|
      format.html
    end
  end

  def create
    @easy_money_object = EasyMoneyExpectedRevenue.new
    @easy_money_object.safe_attributes = params[:easy_money] if params[:easy_money]

    if @easy_money_object.save
      attachments = Attachment.attach_files(@easy_money_object, params[:attachments])
      Redmine::Hook.call_hook(:controller_easy_money_expected_revenues_create_after_save, {:expected_revenue => @easy_money_object, :attachments => attachments, :params => params})

      respond_to do |format|
        format.html {
          render_attachment_warning_if_needed(@easy_money_object)
          flash[:notice] = l(:notice_successful_create)
          params[:continue] ?
            redirect_to(:action => 'new', :project_id => @project, :'easy_money[entity_type]' => @easy_money_object.entity_type, :'easy_money[entity_id]' => @easy_money_object.entity_id ) :
            redirect_back_or_default(:action => 'index', :project_id => @project, :'easy_money[entity_type]' => @easy_money_object.entity_type, :'easy_money[entity_id]' => @easy_money_object.entity_id)
        }
        format.api  { render :action => 'show', :status => :created, :location => url_for(:action => 'show', :id => @easy_money_object, :project_id => @project, :'easy_money[entity_type]' => @easy_money_object.entity_type, :'easy_money[entity_id]' => @easy_money_object.entity_id) }
      end
    else
      respond_to do |format|
        format.html { render :action => 'new' }
        format.api  { render_validation_errors(@easy_money_object) }
      end
    end
  end

  def edit
    flash[:warning] = l(:warning_model_has_easy_external_id) if @easy_money_object.easy_external_id
    respond_to do |format|
      format.html
    end
  end

  def update
    @easy_money_object.safe_attributes = params[:easy_money] if params[:easy_money]

    if @easy_money_object.save
      attachments = Attachment.attach_files(@easy_money_object, params[:attachments])
      Redmine::Hook.call_hook(:controller_easy_money_expected_revenues_update_after_save, {:expected_revenue => @easy_money_object, :attachments => attachments, :params => params})

      respond_to do |format|
        format.html {
          render_attachment_warning_if_needed(@easy_money_object)
          flash[:notice] = l(:notice_successful_update)
          redirect_back_or_default(:action => 'index', :project_id => @project, :'easy_money[entity_type]' => @easy_money_object.entity_type, :'easy_money[entity_id]' => @easy_money_object.entity_id)
        }
        format.api  { render_api_ok }
      end
    else
      respond_to do |format|
        format.html { render :action => 'edit' }
        format.api  { render_validation_errors(@easy_money_object) }
      end
    end
  end

  def destroy
    @easy_money_object.destroy

    respond_to do |format|
      format.html {
        flash[:notice] = l(:notice_successful_delete)
        redirect_back_or_default(:action => 'index', :project_id => @project, :'easy_money[entity_type]' => @easy_money_object.entity_type, :'easy_money[entity_id]' => @easy_money_object.entity_id)
      }
      format.api  { render_api_ok }
    end
  end

  def inline_edit
    respond_to do |format|
      format.js
    end
  end

  def inline_update
    expected_revenue = @entity.expected_revenues.first || @entity.expected_revenues.new(:name => l(:label_easy_money_new_revenue_text), :description => l(:label_easy_money_new_revenue_description), :spent_on => Date.current)

    if @project.easy_money_settings.expected_count_price == 'price1'
      price1 = params[:expected_revenues][:price].to_f
      price2 = EasyMoneyEntity.compute_price2(@project, price1)
    else
      price2 = params[:expected_revenues][:price].to_f
      price1 = EasyMoneyEntity.compute_price1(@project, price2)
    end

    expected_revenue.price1 = price1
    expected_revenue.vat = @project.easy_money_settings.vat.to_f
    expected_revenue.price2 = price2
    expected_revenue.save(:validate => false)

    respond_to do |format|
      format.js
    end
  end

  private

  def set_show_checkbox
    if !@project.blank? && User.current.allowed_to?(:easy_money_move, @project)
      @show_checkbox = true
      @show_move_button = true
    end
  end

  def check_for_project
    render_404 unless @project
  end

  def check_setting_revenues_type
    render_404 if @project && @project.easy_money_settings.revenues_type == 'sum' && @project.expected_revenues.size > 0
  end

  def check_setting_show_expected
    render_404 if @project && !@project.easy_money_settings.show_expected?
  end

  def find_easy_money_object
    @easy_money_object = EasyMoneyExpectedRevenue.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

end
