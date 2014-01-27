module EasyExtensions
  class ExternalResources::ExternalResourceBase < ActiveResource::Base

    add_response_method :http_response

    def inspect
      "#<#{self.class.name} id=#{self.id}>"
    end

  end
end
