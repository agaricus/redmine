module EasyPatch
  module ApplicationControllerPatch

    def self.included(base)
      base.extend(ClassMethods)
      base.send(:include, InstanceMethods)
      base.class_eval do

        has_mobile_fu

        before_filter :set_easy_publishing
        before_filter :ensure_easy_attendance
        before_filter :get_current_easy_issue_timers
        #after_filter  :set_no_cache

        before_filter :clear_used_stylesheets
        after_filter :clear_used_stylesheets

        class_attribute :accept_anonymous_access_actions

        alias_method_chain :check_if_login_required, :easy_extensions
        alias_method_chain :find_current_user, :easy_extensions
        alias_method_chain :per_page_option, :easy_extensions
        alias_method_chain :redirect_back_or_default, :easy_extensions
        alias_method_chain :render_attachment_warning_if_needed, :easy_extensions
        alias_method_chain :render_feed, :easy_extensions
        alias_method_chain :render_validation_errors, :easy_extensions
        alias_method_chain :require_login, :easy_extensions

        def self.accept_anonymous_access(*actions)
          if actions.any?
            self.accept_anonymous_access_actions = actions
          else
            self.accept_anonymous_access_actions || []
          end
        end

        def accept_anonymous_access?(action=action_name)
          self.class.accept_anonymous_access.include?(action.to_sym)
        end

        def easy_page_context
          @__easy_page_ctx
        end

        def clear_used_stylesheets
          @used_stylesheets = []
        end

        def used_stylesheets(s=nil)
          @used_stylesheets ||= []
          if s.nil?
            @used_stylesheets
          else
            @used_stylesheets << s unless @used_stylesheets.include?(s)
          end
        end

        def current_user_ip
          request.env["HTTP_X_FORWARDED_FOR"].blank? ? request.remote_ip : request.env["HTTP_X_FORWARDED_FOR"]
        end

        def parse_params_for_bulk_entity_attributes(entity_params=nil)
          return {} if entity_params.nil?
          attributes = (entity_params).reject {|k,v| v.blank?}
          attributes.keys.each {|k| attributes[k] = '' if attributes[k] == 'none'}
          if custom = attributes[:custom_field_values]
            custom.reject! {|k,v| v.blank?}
            custom.keys.each do |k|
              if custom[k].is_a?(Array)
                custom[k] << '' if custom[k].delete('__none__')
              else
                custom[k] = '' if custom[k] == '__none__'
              end
            end
          end
          attributes
        end

        def render_api_error(msg)
          @error_messages = msg.to_a
          render :template => 'common/error_messages.api', :status => :unprocessable_entity, :layout => nil
        end

        def require_admin_or_lesser_admin(area_name=nil)
          return unless require_login

          if !User.current.easy_lesser_admin_for?(area_name)
            render_403
            return false
          end

          true
        end

        def require_admin_or_api_request_or_lesser_admin(area_name=nil)
          return true if api_request?
          if User.current.easy_lesser_admin_for?(area_name)
            true
          elsif User.current.logged?
            render_error(:status => 406)
          else
            deny_access
          end
        end

        protected

        def set_easy_publishing
          if EasyPublishingSetting.count > 0
            @easy_publishing_help = EasyPublishingSetting.helps.where(:controller => params[:controller], :action => params[:action]).first
            @easy_publishing_help = EasyPublishingSetting.helps.where(:url => '*').first if !@easy_publishing_help
            @easy_publishing_contact = EasyPublishingSetting.contacts.where(:controller => params[:controller], :action => params[:action]).first
            @easy_publishing_contact = EasyPublishingSetting.contacts.where(:url => '*').first if !@easy_publishing_contact
            @easy_publishing_info = EasyPublishingSetting.infos.where(:controller => params[:controller], :action => params[:action]).first
            @easy_publishing_info = EasyPublishingSetting.infos.where(:url => '*').first if !@easy_publishing_info
            @easy_publishing_youtube = EasyPublishingSetting.youtubes.where(:controller => params[:controller], :action => params[:action]).first
            @easy_publishing_youtube = EasyPublishingSetting.youtubes.where(:url => '*').first if !@easy_publishing_youtube
          end
        end

        def count_time(&block)
          start_time = Time.now
          yield
          logger.info(Time.now - start_time)
        end

        def content_types_for_disabled_cache
          @content_types_for_disabled_cache ||= ['', Redmine::MimeType::EXTENSIONS['html']]
          @content_types_for_disabled_cache
        end

        def set_no_cache
          if content_types_for_disabled_cache.include?(response.content_type.to_s)
            response.headers["Cache-Control"] = "no-cache, no-store, max-age=0, must-revalidate"
            response.headers["Pragma"] = "no-cache"
          end
        end

        # Marks current action to be rendered as easy page with custom layout.
        # There is three modes for customizing modules.
        # => user is user, entity_id is nil - My Page. Each user can customize the page.
        # => user is nil, entity id is integer - Project Page. Each project has a different page that is the same for all users.
        # => user is user, entity id is integer - Each entity page has a different page that is customizable for each user.
        # Params:
        # => page - EasyPage instance to be rendered
        # => user - determines which page modules will be loaded. If the user is nil than it means that the page has no dependency on user.
        # => entity_id - it is any ID for resolution of the current Page (e.g. 31 for Project ID 31, nil for the My Page)
        # => back_url - url for redirecting back
        # => edit - true / false. If true, the page is rendered in edit mode.
        # => page_context - additional informations about page. E.g. :project if project_controller
        def render_action_as_easy_page(page, user = nil, entity_id = nil, back_url = nil, edit = false, page_context = {})
          return false unless page.is_a?(EasyPage)

          raise StandardError, "No zones defined for a page: #{page.page_name}" if page.zones.empty?

          tab = params[:t].to_i
          tab = 1 if tab <= 0
          page_tab = EasyPageUserTab.where(:page_id => page.id, :user_id => user && user.id, :entity_id => entity_id, :position => tab).first
          page_params = create_page_params_for_easy_page(page, user, entity_id, back_url, edit)
          page_modules = page.user_tab_modules(page_tab, user, entity_id)

          @easy_page_modules_data = {}

          page_modules.each do |zone_name, page_modules_in_zone|
            page_modules_in_zone.each do |page_module|
              if edit
                @easy_page_modules_data[page_module.module_name] = page_module.get_edit_data(user || User.current, params[page_module.module_name], page_context)
              else
                @easy_page_modules_data[page_module.module_name] = page_module.get_show_data(user || User.current, params[page_module.module_name], page_context)
              end
            end
          end

          @__easy_page_ctx = {:page_modules => page_modules, :page_params => page_params}
          self.class.layout page.layout_path

          return true
        end

        # Marks current action to be rendered as easy page template with custom layout.
        # There is three modes for customizing modules.
        # => user is user, entity_id is nil - My Page. Each user can customize the page.
        # => user is nil, entity id is integer - Project Page. Each project has a different page that is the same for all users.
        # => user is user, entity id is integer - Each entity page has a different page that is customizable for each user.
        # Params:
        # => page_template - EasyPageTemplate instance to be rendered
        # => user - determines which page modules will be loaded. If the user is nil than it means that the page has no dependency on user.
        # => entity_id - it is any ID for resolution of the current Page (e.g. 31 for Project ID 31, nil for the My Page)
        # => back_url - url for redirecting back
        # => edit - true / false. If true, the page is rendered in edit mode.
        # => page_context - additional informations about page. E.g. :project if project_controller
        def render_action_as_easy_page_template(page_template, user = nil, entity_id = nil, back_url = nil, edit = false, page_context = {})
          return false unless page_template.is_a?(EasyPageTemplate)
          page = page_template.page_definition

          raise StandardError, "No zones defined for a page: #{page.page_name}" if page.zones.empty?

          tab = params[:t].to_i
          tab = 1 if tab <= 0
          page_tab = EasyPageTemplateTab.where(:page_template_id => page_template.id, :entity_id => entity_id, :position => tab).first
          page_params = create_page_params_for_easy_page_template(page_template, page, user, entity_id, back_url, edit)
          page_template_modules = page_template.template_tab_modules(page_tab, entity_id)

          @easy_page_modules_data = {}

          page_template_modules.each do |zone_name, page_template_modules_in_zone|
            page_template_modules_in_zone.each do |page_template_module|
              if edit
                @easy_page_modules_data[page_template_module.module_name] = page_template_module.get_edit_data(user, params[page_template_module.module_name], page_context)
              else
                @easy_page_modules_data[page_template_module.module_name] = page_template_module.get_show_data(user, params[page_template_module.module_name], page_context)
              end
            end
          end

          @__easy_page_ctx = {:page_modules => page_template_modules, :page_params => page_params}
          self.class.layout page.layout_path

          return true
        end

        # Marks current action to be rendered as easy page template tab with custom layout.
        # There is three modes for customizing modules.
        # => user is user, entity_id is nil - My Page. Each user can customize the page.
        # => user is nil, entity id is integer - Project Page. Each project has a different page that is the same for all users.
        # => user is user, entity id is integer - Each entity page has a different page that is customizable for each user.
        # Params:
        # => page_template - EasyPageTemplate instance to be rendered
        # => user - determines which page modules will be loaded. If the user is nil than it means that the page has no dependency on user.
        # => entity_id - it is any ID for resolution of the current Page (e.g. 31 for Project ID 31, nil for the My Page)
        # => edit - true / false. If true, the page is rendered in edit mode.
        # => page_context - additional informations about page. E.g. :project if project_controller
        def render_action_as_easy_tab_content(page_tab, page, user = nil, entity_id = nil, back_url = nil, edit = false, page_context = {})
          if page.is_a?(EasyPageTemplate)
            page_template = page
            page = page_template.page_definition
          end
          return false unless page.is_a?(EasyPage)

          raise StandardError, "No zones defined for a page: #{page.page_name}" if page.zones.empty?

          tab = page_tab.position
          if page_tab.is_a?(EasyPageUserTab)
            page_params = create_page_params_for_easy_page(page, user, entity_id, back_url, edit)
            page_modules = page.user_tab_modules(page_tab, user, entity_id)
          elsif page_tab.is_a?(EasyPageTemplateTab)
            page_params = create_page_params_for_easy_page_template(page_template, page, user, entity_id, back_url, edit)
            page_modules = page_template.template_tab_modules(page_tab, entity_id)
          end

          @easy_page_modules_data = {}

          page_modules.each do |zone_name, page_modules_in_zone|
            page_modules_in_zone.each do |page_module|
              if edit
                @easy_page_modules_data[page_module.module_name] = page_module.get_edit_data(user || User.current, params[page_module.module_name], page_context)
              else
                @easy_page_modules_data[page_module.module_name] = page_module.get_show_data(user || User.current, params[page_module.module_name], page_context)
              end
            end
          end

          @__easy_page_ctx = {:page_modules => page_modules, :page_params => page_params}
          self.class.layout false

          return true
        end

        def create_page_params_for_easy_page(page, user = nil, entity_id = nil, back_url = nil, edit = false)
          raise ArgumentError, 'User have to be a user.' if user && !user.is_a?(User)
          user_id = user.id if user
          tabs = EasyPageUserTab.page_tabs(page, user_id, entity_id)
          {:page => page, :user => user, :user_id => user_id,
            :entity_id => entity_id, :back_url => back_url, :edit => edit, :tabs => tabs, :current_tab => get_selected_page_tab(tabs),
            :url_order_module =>  { :controller => 'easy_page_layout', :action => 'order_module', :page_id => page.id, :user_id => user_id, :entity_id => entity_id, :project_id => params[:project_id] },
            :url_add_module =>    { :controller => 'easy_page_layout', :action => "add_module", :page_id => page.id, :user_id => user_id, :entity_id => entity_id, :project_id => params[:project_id] },
            :url_remove_module => { :controller => 'easy_page_layout', :action => "remove_module", :page_id => page.id, :user_id => user_id, :entity_id => entity_id, :project_id => params[:project_id] },
            :url_save_modules =>  { :controller => 'easy_page_layout', :action => 'save_module', :page_id => page.id, :user_id => user_id, :entity_id => entity_id, :project_id => params[:project_id] } }
        end

        def create_page_params_for_easy_page_template(page_template, page, user = nil, entity_id = nil, back_url = nil, edit = false)
          raise ArgumentError, 'User have to be a user.' if user && !user.is_a?(User)
          user_id = user.id if user
          tabs = EasyPageTemplateTab.page_template_tabs(page_template, entity_id)
          {:page_template => page_template, :page => page, :user => user, :user_id => user_id,
            :entity_id => entity_id, :back_url => back_url, :edit => edit, :tabs => tabs, :current_tab => get_selected_page_tab(tabs),
            :url_order_module =>  { :controller => 'easy_page_template_layout', :action => 'order_module', :id => page_template.id, :entity_id => entity_id },
            :url_add_module =>    { :controller => 'easy_page_template_layout', :action => "add_module", :id => page_template.id, :entity_id => entity_id },
            :url_remove_module => { :controller => 'easy_page_template_layout', :action => "remove_module", :id => page_template.id, :entity_id => entity_id },
            :url_save_modules =>  { :controller => 'easy_page_template_layout', :action => 'save_module', :id => page_template.id, :entity_id => entity_id } }
        end

        def render_single_easy_page_module(page_module, page_module_render_settings = nil, page = nil, user = nil, entity_id = nil, back_url = nil, edit = nil, with_container = false, page_context = {})
          partial, locals = prepare_render_for_single_easy_page_module(page_module, page_module_render_settings, page, user, entity_id, back_url, edit, with_container, page_context)
          render :partial => partial, :locals => locals
        end

        def prepare_render_for_single_easy_page_module(page_module, page_module_render_settings = nil, page = nil, user = nil, entity_id = nil, back_url = nil, edit = nil, with_container = false, page_context = {})
          raise ArgumentError, 'The page_module variable have to be a EasyPageZoneModule' unless page_module.is_a?(EasyPageZoneModule)
          page ||= page_module.page_definition
          user ||= page_module.user
          user ||= User.current

          if back_url.nil?
            back_url = params[:back_url] || url_for(params)
          end

          if edit.nil?
            edit = params[:edit] || false
          end

          if entity_id.nil?
            entity_id = params[:entity_id]
          end

          if page_module_render_settings.nil?
            if edit
              page_module_render_settings = page_module.get_edit_data(user, params[page_module.module_name], page_context)
            else
              page_module_render_settings = page_module.get_show_data(user, params[page_module.module_name], page_context)
            end
          end

          page_params = create_page_params_for_easy_page(page, user, entity_id, back_url, edit)

          @easy_page_modules_data ||= {}
          @easy_page_modules_data[page_module.module_name] = page_module_render_settings || {}

          partial = "easy_page_layout/page_module_#{edit ? 'edit' : 'show'}#{with_container ? '_container' : ''}"
          locals = {:page_params => page_params, :page_module => page_module}

          return partial, locals
        end

        def ensure_easy_attendance
          if User.current.logged? && EasyAttendance.enabled? && [nil, 'html', 'mobile'].include?(request.format) && EasyAttendanceActivity.exists?(:is_default => true)
            #easy_attendance = EasyAttendance.new_or_last_attendance(User.current)
            #            if easy_attendance.arrival?
            if User.current.empty_today_attendance? && (User.current.current_working_time_calendar.nil? || (User.current.current_working_time_calendar && User.current.current_working_time_calendar.working_day?(Date.today)))
              easy_attendance = EasyAttendance.new
              easy_attendance.new_arrival = true
              easy_attendance.arrival = User.current.user_time_in_zone
              easy_attendance.user = User.current

              easy_attendance.current_user_ip = current_user_ip
              activity = EasyAttendanceActivity.for_ip(current_user_ip)
              return if activity.blank?
              easy_attendance.easy_attendance_activity = activity
              easy_attendance.save
              EasyAttendanceUserArrivalNotify.where(:user_id => User.current).each do |e|
                e.send_notify!
              end
            end
          end
        end

        def get_current_easy_issue_timers
          if User.current.logged?
            @easy_issue_timers = EasyIssueTimer.where(:user_id => User.current.id).running.includes(:issue)
          end
        end

        private

        def get_selected_page_tab(tabs)
          return nil if tabs.blank?
          selected_tab = nil

          tabs.each do |tab|
            if params[:tab_id] && tab.id == params[:tab_id].to_i
              selected_tab = tab
              break
            elsif params[:t] && tab.position == params[:t].to_i
              selected_tab = tab
              break
            end
          end

          selected_tab || tabs.first
        end

      end
    end

    module InstanceMethods

      def find_current_user_with_easy_extensions
        user = nil
        if session[:user_id]
          # existing session
          user = (User.active.find(session[:user_id]) rescue nil)
        end
        if user.nil? && !api_request?
          if autologin_user = try_to_autologin
            user = autologin_user
          elsif params[:format] == 'atom' && params[:key] && request.get? && accept_rss_auth?
            # RSS key authentication does not start a session
            user = User.find_by_rss_key(params[:key])
          end
        end
        if user.nil? && Setting.rest_api_enabled? && accept_api_auth?
          if (key = api_key_from_request)
            # Use API key
            user = User.find_by_api_key(key)
          else
            # HTTP Basic, either username/password or API key/random
            authenticate_with_http_basic do |username, password|
              user = User.try_to_login(username, password) || User.find_by_api_key(username)
            end
            if user && user.must_change_password?
              render_error :message => 'You must change your password', :status => 403
              return
            end
          end
          # Switch user if requested by an admin user
          if user && user.admin? && (username = api_switch_user_from_request)
            su = User.find_by_login(username)
            if su && su.active?
              logger.info(" User switched by: #{user.login} (id=#{user.id})") if logger
              user = su
            else
              render_error :message => 'Invalid X-Redmine-Switch-User header', :status => 412
            end
          end
        end
        user
      end

      def require_login_with_easy_extensions
        if !User.current.logged?
          # Extract only the basic url parameters on non-GET requests
          if request.get?
            url = url_for(params)
          else
            url = url_for(:controller => params[:controller], :action => params[:action], :id => params[:id], :project_id => params[:project_id])
          end
          format_mobile = :mobile if is_mobile_device?
          respond_to do |format|
            format.html {
              if request.xhr?
                head :unauthorized
              else
                redirect_to :controller => "account", :action => "login", :back_url => url, :format => format_mobile
              end
            }
            format.atom { redirect_to :controller => "account", :action => "login", :back_url => url }
            format.xml  { head :unauthorized, 'WWW-Authenticate' => 'Basic realm="The credentials to Easy Project has expired, please log in"' }
            format.js   { head :unauthorized, 'WWW-Authenticate' => 'Basic realm="The credentials to Easy Project has expired, please log in"' }
            format.json { head :unauthorized, 'WWW-Authenticate' => 'Basic realm="The credentials to Easy Project has expired, please log in"' }
          end
          return false
        end
        true
      end

      def render_feed_with_easy_extensions(items, options={})
        @items = items || []
        @items.sort! {|x,y| y.event_datetime <=> x.event_datetime }
        @items = @items.slice(0, Setting.feeds_limit.to_i)
        @title = options[:title] || Setting.app_title
        render :template => (options[:template] || 'common/feed'), :formats => [:atom], :layout => false, :content_type => 'application/atom+xml'
      end

      def render_attachment_warning_if_needed_with_easy_extensions(obj)
        if obj.unsaved_attachments.present?
          flash[:warning] = l(:warning_attachments_not_saved, obj.unsaved_attachments.size)
          obj.unsaved_attachments.each do |att|
            att.errors.each do |attribute, err|
              flash[:warning] = attribute == :description ? "#{l(:field_description)} #{err}" : err
            end
          end
        end
      end

      def per_page_option_with_easy_extensions
        if params[:per_page] && params[:per_page] == 'all'
          nil
        else
          per_page_option_without_easy_extensions
        end
      end

      def render_validation_errors_with_easy_extensions(objects)
        if objects.is_a?(Array)
          @error_messages = objects.map {|object| object.errors.full_messages}.flatten
        else
          @error_messages = objects.errors.full_messages
        end

        logger.info 'API ERROR:'
        logger.info @error_messages

        render :template => 'common/error_messages.api', :status => :unprocessable_entity, :layout => nil
      end

      def redirect_back_or_default_with_easy_extensions(default)
        back_url = params[:back_url2].to_s
        if back_url.present?
          begin
            uri = URI.parse(back_url)
            # do not redirect user to another host or to the login or register page
            if (uri.relative? || (uri.host == request.host)) && !uri.path.match(%r{/(login|account/register)})
              redirect_to(back_url)
              return
            end
          rescue URI::InvalidURIError
            logger.warn("Could not redirect to invalid URL #{back_url}")
            # redirect to default
          end
        end
        redirect_back_or_default_without_easy_extensions(default)
      end

      def check_if_login_required_with_easy_extensions
        if !accept_anonymous_access?
          check_if_login_required_without_easy_extensions
        end
      end

    end

    module ClassMethods

    end

  end

end
EasyExtensions::PatchManager.register_controller_patch 'ApplicationController', 'EasyPatch::ApplicationControllerPatch'
