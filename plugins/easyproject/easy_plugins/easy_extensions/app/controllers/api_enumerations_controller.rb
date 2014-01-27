class ApiEnumerationsController < ApplicationController

  before_filter :require_admin

  helper :sort
  include SortHelper
  helper :api_custom_fields
  include ApiCustomFieldsHelper

  accept_api_auth :index

  def index
    sort_init 'type', 'asc'
    sort_update 'type' => 'type'

    scope = Enumeration.scoped
    scope = scope.where(:type => params[:type]) unless params[:type].blank?

    respond_to do |format|
      format.api  {
        @enumerations_count = scope.count
        @offset, @limit = api_offset_and_limit
        @enumerations = scope.order(sort_clause).limit(@limit).offset(@offset).all
      }
    end
  end

end