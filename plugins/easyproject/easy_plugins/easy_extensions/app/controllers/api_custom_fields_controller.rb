class ApiCustomFieldsController < ApplicationController

  before_filter :require_admin
  before_filter :find_custom_field, :only => [:show, :update, :destroy]

  helper :sort
  include SortHelper
  helper :api_custom_fields
  include ApiCustomFieldsHelper

  accept_api_auth :index, :show, :create, :update, :destroy

  def index
    sort_init 'type', 'asc'
    sort_update 'type' => 'type'

    scope = CustomField.scoped
    scope = scope.where(:type => params[:type]) unless params[:type].blank?

    respond_to do |format|
      format.api  {
        @custom_fields_count = scope.count
        @offset, @limit = api_offset_and_limit
        @custom_fields = scope.order(sort_clause).limit(@limit).offset(@offset).all
      }
    end
  end

  def show
    respond_to do |format|
      format.api
    end
  end

  def create
    cf_type = params[:custom_field][:type] if params[:custom_field].is_a?(Hash)
    cf_type ||= params[:type]
    
    @custom_field = cf_type.constantize.new

    unless @custom_field.is_a?(CustomField)
      render_404
      return
    end
    
    @custom_field.attributes = params[:custom_field]

    if @custom_field.save
      respond_to do |format|
        format.api  { render :action => 'show', :status => :created, :location => {:controller => :api_custom_fields, :action => :show, :id => @custom_field} }
      end
    else
      respond_to do |format|
        format.api  { render_validation_errors(@custom_field) }
      end
    end
  end

  def update
    @custom_field.attributes = params[:custom_field]

    if @custom_field.save
      respond_to do |format|
        format.api  { render_api_ok }
      end
    else
      respond_to do |format|
        format.api  { render_validation_errors(@custom_field) }
      end
    end
  end

  def destroy
    @custom_field.destroy

    respond_to do |format|
      format.api  { render_api_ok }
    end

    respond_to do |format|
      format.api
    end
  end

  private

  def find_custom_field
    if params[:id]
      if params[:id].match(/^\d+$/)
        @custom_field = CustomField.where(:id => params[:id]).first
      else
        @custom_field = CustomField.where(:internal_name => params[:id]).first
      end
    end

    render_404 unless @custom_field
  end

end