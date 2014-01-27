class EasySlidingPanelsController < ApplicationController
  def save_location
    @panel = User.current.easy_sliding_panels_locations.where(:name => params[:panel_name]).first
    @panel ||= User.current.easy_sliding_panels_locations.build(:name => params[:panel_name])

    @panel.zone = params[:panel_zone]
    @panel.save

    respond_to do |format|
      format.js {render :nothing => true}
    end
  end
end
