module EasyPatch
  module AccountControllerPatch

    def self.included(base)

      base.class_eval do

        helper :attachments
        include AttachmentsHelper

        accept_api_auth :autologin

        before_filter :resolve_layout, :except => [:get_avatar]

        def autologin
          if Setting.rest_api_enabled? && accept_api_auth? && (key = api_key_from_request)
            if user = User.find_by_api_key(key)
              self.logged_user = user
              set_autologin_cookie(user)
            end
          end

          redirect_back_or_default(home_url)
        end

        private

        def resolve_layout
          if (in_mobile_view? || params[:format] == :mobile)
            self.class.layout 'login', :formats => :mobile
          else
            self.class.layout 'base'
          end
        end


      end
    end

  end
end
EasyExtensions::PatchManager.register_controller_patch 'AccountController', 'EasyPatch::AccountControllerPatch'
