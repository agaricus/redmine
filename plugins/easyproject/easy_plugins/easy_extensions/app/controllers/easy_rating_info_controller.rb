class EasyRatingInfoController < ApplicationController

  def show
    @custom_value = CustomValue.find(params[:id])
    params[:page]
    @ratings_count = @custom_value.easy_custom_field_ratings.count
    @ratings = @custom_value.easy_custom_field_ratings
    @ratings_pages, @ratings = paginate_collection(@ratings, {:page => params[:page], :per_page => 3})
    respond_to do |format|
      format.html {render :partial => 'rating_info'}
    end
  end

end