module EasyExternalAuthentications
  class AuthenticationProvider
    class ClientUnconfiguredError < StandardError; end
    class ObtainRequestTokenError < StandardError; end
    
    include Singleton
    include ActionDispatch::Http::URL

    attr_reader :request_token

    def self.inherited(child)
      EasyExternalAuthentication.add_provider(child)
      super
    end

    def name
      raise NotImplementedError, 'child has to implement a name'
    end

    def connect; end
    def create_authentication(params={})
      @access_token = request_token.get_access_token(:oauth_verifier => params['oauth_verifier'])
      authentication = EasyExternalAuthentication.new(:uid => extract_uid(@access_token), :access_token => @access_token.token, :provider => name)
      if @request_type == 'user'
        authentication.user = User.current
      end
      set_authentication_params(authentication, params)
      authentication.save
    end
    
    def configure(options={})
      @request_type = options[:type]
    end

    def authorize_url(host)
      @request_token = client.request_token(:oauth_callback => callback_url(host))
      raise ObtainRequestTokenError unless request_token
      request_token.authorize_url
    rescue ClientUnconfiguredError => e
      raise NotImplementedError, 'Please provide an client method or overwrite an authorize_url method'
    end

    def client(token = nil)
      raise ClientUnconfiguredError
    end

    #if you want to ask an user for someting or you have other things to do before delete an record
    def destroy_url(id, referer)
      false
    end

    def destroy(id)
      if destroy_allowed?(id)
        EasyExternalAuthentication.destroy(id)
      else
        false
      end
    end

    protected
      def destroy_allowed?(id)
        return true if User.current.admin?

        return true if EasyExternalAuthentication.find(id).user == User.current

        false
      end

      def callback_url(host)
        Rails.application.routes.url_helpers.easy_external_authentication_callback_url(:provider=>name, :host=>host)
      end

      def extract_uid(access_token)
        raise NotImplementedError, 'provider has to implement uid method'
      end

      # if you wish to save something more than it saves by default
      # => authentication EasyExternalAuthentication instance about to be saved
      # => params witch has been send from third party
      def set_authentication_params(authentication, params={}); end
  end
end