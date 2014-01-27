class EasyResourceAvailabilitiesController < ApplicationController

  before_filter :require_login
  before_filter :authorize_global, :only => [:edit_page_layout]

  def update
    uuid = params[:uuid]
    date = params[:date].to_date
    hour = params[:hour].blank? ? nil : params[:hour].to_i
    available = !params[:available].blank?
    day_start_time = params[:day_start_time].to_i
    day_end_time = params[:day_end_time].to_i
    description = params[:description]

    EasyResourceAvailability.set_availability(uuid, date, hour, available, description, day_start_time, day_end_time)

    render :nothing => true
  end

  def index
    render_action_as_easy_page(EasyPage.page_easy_resource_booking_module, nil, nil, easy_resource_availabilities_url, false)
  end

  def edit_page_layout
    render_action_as_easy_page(EasyPage.page_easy_resource_booking_module, nil, nil, easy_resource_availabilities_url, true)
  end

end
