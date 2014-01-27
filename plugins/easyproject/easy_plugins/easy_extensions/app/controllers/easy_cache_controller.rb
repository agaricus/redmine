class EasyCacheController < ApplicationController

  def delete_all

    FileUtils.rm Dir[ActionController::Base.cache_store.cache_path + '/views/*.cache']

    flash[:notice] = l(:notice_successful_delete)
    params[:back_url].nil? ? redirect_to(:back) : redirect_to(params[:back_url])
  end

end