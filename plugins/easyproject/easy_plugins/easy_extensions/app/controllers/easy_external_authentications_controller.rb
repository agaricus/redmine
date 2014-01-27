class EasyExternalAuthenticationsController < ApplicationController
  
  before_filter :find_provider
  # used for setup omniauth client and other stuffs
  before_filter :configure, :only => [:new, :create]

  def new
    session[:easy_auth_referer] = request.env['HTTP_REFERER']
    redirect_to @provider.authorize_url(request.host_with_port)
  rescue EasyExternalAuthentication::AuthenticationProvider::ObtainRequestTokenError => e
    flash[:error] = l(:error_request_token_obtain)
    redirect_to :back
  end

  def create
    unless params['oauth_verifier']
      flash[:error] = l(:error_oauth_authorization)
    else
      @provider.create_authentication(params)
    end
    redirect_to session[:easy_auth_referer]
  end

  def destroy
    referer = request.env['HTTP_REFERER']
    url = @provider.destroy_url(params[:id], referer)
    if url
      redirect_to url
    else
      if @provider.destroy(params[:id])
        flash[:notice] = l(:notice_easy_external_authorization_destroyed, :provider => @provider.name)
      else
        flash[:error] = l(:error_oauth_destroy_failed, :provider => @provider.name)
      end
      redirect_to :back
    end
  end

  private

    def find_provider
      @provider = EasyExternalAuthentication.providers.detect{|provider| provider.name == params[:provider]}
    end

    def configure
      @provider.configure(:type => params[:type])
    end

end