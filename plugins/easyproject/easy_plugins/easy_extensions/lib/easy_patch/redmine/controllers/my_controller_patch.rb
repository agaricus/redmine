module EasyPatch
  module MyControllerPatch

    def self.included(base)
      base.send(:include, InstanceMethods)

      base.class_eval do

        menu_item :my_page

        helper :projects
        include ProjectsHelper
        helper :timelog
        include TimelogHelper
        helper :entity_attribute
        include EntityAttributeHelper
        helper :easy_query
        include EasyQueryHelper
        helper :attachments
        include AttachmentsHelper
        helper :sort
        include SortHelper
        helper :easy_page_modules
        include EasyPageModulesHelper
        helper :issue_relations
        include IssueRelationsHelper
        helper :easy_attendances
        include EasyAttendancesHelper

        skip_before_filter :require_login
        before_filter :prepare_values_for_my_page_new_issue, :only => [:update_my_page_new_issue_attributes, :new_my_page_create_issue, :update_my_page_new_issue_dependent_fields]
        before_filter :authorize_new_my_page_create_issue, :only => [:new_my_page_create_issue]
        before_filter :check_if_login_required, :except => [:toggle_mobile_view]

        alias_method_chain :page_layout, :easy_extensions
        alias_method_chain :page, :easy_extensions
        alias_method_chain :account, :easy_extensions

        def update_my_page_new_issue_dependent_fields
        end

        def update_my_page_new_issue_attributes
        end

        def new_my_page_create_issue
          @project = nil
          @issue.author = User.current

          respond_to do |format|
            @issue.save_attachments(params[:attachments] || (params[:issue] && params[:issue][:uploads]))
            if @issue.save
              flash[:notice] = l(:notice_issue_successful_create, :id => view_context.link_to("#{@issue.to_s}", issue_path(@issue), :title => @issue.subject)).html_safe

              format.html {
                render_attachment_warning_if_needed(@issue)
                redirect_back_or_default :controller => 'my', :action => 'page'
              }
            else
              format.html {
                render_action_as_easy_page(EasyPage.page_my_page, User.current, nil, url_for(:controller => 'my', :action => 'page', :t => params[:t]), false, {:issue => @issue})
              }
            end
          end
        end

        def update_my_page_module_view
          epzm = EasyPageZoneModule.find(params[:uuid], :include => [:user, :page_definition, :module_definition])
          respond_to do |format|
            format.html {render_single_easy_page_module(epzm)}
            format.js {@module_partial, @module_locals = prepare_render_for_single_easy_page_module(epzm)}
          end
        end

        def toggle_mobile_view
          session[:mobile_view] = !session[:mobile_view]

          redirect_back_or_default('/')
        end

        def mobile_page_layout
          @user = User.current
          render_action_as_easy_page(EasyPage.page_my_mobile_page, User.current, nil, url_for(:controller => 'my', :action => 'page', :t => params[:t]), true)
        end

        private

        def prepare_values_for_my_page_new_issue
          if params[:block_name].nil?
            redirect_to :controller => 'my', :action => 'page'
          else

            my_params = params[params[:block_name]+'issue']
            my_params[:update_form] = request.xhr?
            @user = User.find(params[:user_id])
            @project = Project.where({:id => my_params[:project_id]}).first
            @issue = Issue.new
            @issue.project = @project
            if @project
              tracker_id = my_params.delete :tracker_id
              if @project.trackers.exists?(tracker_id)
                @issue.tracker = @project.trackers.find(tracker_id)
              else
                @issue.tracker = @project.trackers.first
              end
            end
            @issue.author = @user
            @issue.safe_attributes = my_params
            @issue.start_date ||= Date.today

            #@projects = Project.visible(@user).non_templates
            @issue_priorities = IssuePriority.active
            @assignable_users = @issue.assignable_users
            @allowed_statuses = @issue.new_statuses_allowed_to(@user, true)


            if User.current.allowed_to?(:add_issue_watchers, @issue.project) && @issue.new_record? && my_params['watcher_user_ids']
              @issue.watcher_user_ids = my_params['watcher_user_ids']
            end

            @issue_data = { params[:block_name] => @issue }
          end
        end

        def authorize_new_my_page_create_issue
          if @project
            authorize
          else
            authorize_global
          end
        end

      end

    end

    module InstanceMethods

      # Edit user's account
      def account_with_easy_extensions
        @user = User.current
        @pref = @user.pref
        if request.post?
          @user.safe_attributes = params[:user]
          @user.pref.attributes = params[:pref]
          @user.pref[:no_notified_if_issue_closing] = (params[:no_notified_if_issue_closing] == '1')
          @user.pref[:no_notification_ever] = (params[:no_notification_ever] == '1')
          @user.pref[:user_theme] = params[:user_theme] if params[:user_theme]
          if @user.save
            @user.pref.save
            set_language_if_valid @user.language
            flash[:notice] = l(:notice_account_updated)
            if params[:user].is_a?(Hash) && !params[:user][:avatar].blank?
              # DRY easy_avatars_controller#create
              @user.avatar = nil
              @user.update_attribute('easy_avatar', nil)
              file_field = params[:user][:avatar]
              @user.save_attachments({'first' => {'file' => file_field, 'description' => 'avatar'}}, @user)
              @user.attach_saved_attachments
              @user.reload
              av = @user.avatar
              @user.update_attribute('easy_avatar', av.disk_filename.to_s) if av

              begin
                resize_image_to_fit(av.diskfile, 240, 320) if av
              rescue
              end

              if Object.const_defined?(:Magick)
                redirect_to(crop_easy_avatar_path(:entity_id => @user, :entity_type => @user.class.name, :back_url => params[:back_url]), :timestamp => Time.now.to_i)
              end
            end
          end
        end
      end

      def page_layout_with_easy_extensions
        @user = User.current
        render_action_as_easy_page(EasyPage.page_my_page, User.current, nil, url_for(:controller => 'my', :action => 'page', :t => params[:t]), true)
      end

      def page_with_easy_extensions
        @user = User.current
        if in_mobile_view?
          render_action_as_easy_page(EasyPage.page_my_mobile_page, User.current, nil, url_for(:controller => 'my', :action => 'page'), false)
        else
          render_action_as_easy_page(EasyPage.page_my_page, User.current, nil, url_for(:controller => 'my', :action => 'page', :t => params[:t]), false)
        end
      end
    end
  end

end
EasyExtensions::PatchManager.register_controller_patch 'MyController', 'EasyPatch::MyControllerPatch'
