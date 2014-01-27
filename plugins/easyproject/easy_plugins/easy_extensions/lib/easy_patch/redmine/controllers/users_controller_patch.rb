module EasyPatch
  module UsersControllerPatch

    def self.included(base)
      base.send(:include, InstanceMethods)

      base.class_eval do

        before_filter :require_admin, :except => [:show, :save_button_settings, :generate_rss_key, :generate_api_key, :save_publishing_state]
        before_filter :authorize_users, :only => [:add]
        before_filter :generate_key, :only => [:generate_rss_key, :generate_api_key]
        before_render :change_layout

        helper :issues
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

        alias_method_chain :create, :easy_extensions
        alias_method_chain :edit, :easy_extensions
        alias_method_chain :edit_membership, :easy_extensions
        alias_method_chain :index, :easy_extensions
        alias_method_chain :require_admin, :easy_extensions
        alias_method_chain :show, :easy_extensions
        alias_method_chain :update, :easy_extensions

        def generate_rss_key
        end

        def generate_api_key
        end

        def save_button_settings
          unless params[:uniq_id].blank? || params[:open].blank?
            if params[:user].blank?
              user = User.current
            else
              user = User.find(params[:user])
            end
            # settings & preferences
            pref = user.preference.others[:plus_button_status]
            if pref.nil?
              pref = user.preference.others
              pref[:plus_button_status] = {params[:uniq_id] => params[:open].to_boolean}
            else
              pref[params[:uniq_id]] = params[:open].to_boolean
            end
            # update
            user.preference.update_attributes(:others => pref)
          end

          render :nothing => true
        end

        def save_publishing_state
          if params[:user].blank?
            user = User.current
          else
            user = User.find(params[:user])
          end
          # settings & preferences
          pref = user.pref.others[:easy_publishing_state]
          if pref.nil?
            pref = user.pref.others
            pref[:easy_publishing_state] = {params[:uniq_id] => params[:hide].to_boolean}
          else
            pref[params[:uniq_id]] = params[:hide].to_boolean
          end
          # update
          user.pref.update_attributes(:others => pref)
          render :nothing => true
        end

        private

        def generate_key
          @new_key = Token.generate_token_value
        end

        def change_layout
          self.class.layout('admin') unless params[:tab] == 'my_page'
        end

        def users_project_scope
          @user.memberships.where(Project.visible_condition(User.current)).where(["#{Project.table_name}.easy_is_easy_template = ?", false]).reorder("#{Project.table_name}.lft")
        end

        # autorize add user for limit
        def authorize_users
          if EasyLicenseManager.has_license_limit?(:user_limit)
            return true
          else
            render_403
            return false
          end
        end

      end
    end

    module InstanceMethods

      def index_with_easy_extensions
        retrieve_query(EasyUserQuery)

        sort_init(@query.sort_criteria_init)
        sort_update({'id' => "#{User.table_name}.id"}.merge(@query.sortable_columns))

        case params[:format]
        when 'csv', 'pdf', 'ics'
          @limit = Setting.issues_export_limit.to_i
        when 'atom'
          @limit = Setting.feeds_limit.to_i
        when 'xml', 'json'
          @offset, @limit = api_offset_and_limit
        else
          @limit = per_page_option
        end

        @user_count = @query.entity_count
        @user_pages = Redmine::Pagination::Paginator.new @user_count, @limit, params['page']

        if request.xhr? && @user_pages.last_page.to_i < params['page'].to_i
          render_404
          return false
        end

        @offset ||= @user_pages.offset

        @users = @query.prepare_result(:order => sort_clause, :offset => @offset, :limit => @limit)

        respond_to do |format|
          format.html {
            if request.xhr? && params[:easy_query_q]
              render(:partial => 'easy_queries/easy_query_entities_list', :locals => {:query => @query, :entities => @users})
            else
              render :layout => !request.xhr?
            end
          }
          format.api
          format.csv  { send_data(export_to_csv(@users, @query), :filename => get_export_filename(:csv, @query)) }
          format.pdf  { send_data(export_to_pdf(@users, @query), :filename => get_export_filename(:pdf, @query)) }
        end

      end

      def show_with_easy_extensions
        # show projects based on current user visibility
        @memberships = users_project_scope.all

        events = Redmine::Activity::Fetcher.new(User.current, :author => @user).events(nil, nil, :limit => 10)
        @events_by_day = events.group_by(&:event_date)

        unless User.current.admin?
          if !@user.active? || (@user != User.current  && @memberships.empty? && events.empty?)
            render_404
            return
          end
        end

        respond_to do |format|
          format.html { render :layout => 'base' }
          format.api
        end
      end

      def create_with_easy_extensions
        @user = User.new(:language => Setting.default_language, :mail_notification => Setting.default_notification_option)
        @user.safe_attributes = params[:user]
        @user.admin = params[:user][:admin] || false
        @user.login = params[:user][:login]
        @user.password, @user.password_confirmation = params[:user][:password], params[:user][:password_confirmation] unless @user.auth_source_id

        if @user.save
          @user.pref.attributes = params[:pref]
          @user.pref.save

          unless params[:page_template_id].blank?
            begin
              page_template = EasyPageTemplate.find(params[:page_template_id].to_i)
              EasyPageZoneModule.create_from_page_template(page_template, @user.id)
            rescue ActiveRecord::RecordNotFound
            end
          end

          unless params[:copy_roles_from].blank?
            source_user = User.find(params[:copy_roles_from]) rescue nil;
            @user.copy_roles_from(source_user) if source_user
          end

          Mailer.account_information(@user, @user.password).deliver if params[:send_information]

          respond_to do |format|
            format.html {
              flash[:notice] = l(:notice_user_successful_create, :id => view_context.link_to(@user.login, user_path(@user))).html_safe
              if params[:continue]
                attrs = params[:user].slice(:generate_password)
                redirect_to new_user_path(:user => attrs)
              else
                redirect_to edit_user_path(@user)
              end
            }
            format.api  { render :action => 'show', :status => :created, :location => user_url(@user) }
          end
        else
          @auth_sources = AuthSource.all
          # Clear password input
          @user.password = @user.password_confirmation = nil

          respond_to do |format|
            format.html { render :action => 'new' }
            format.api  { render_validation_errors(@user) }
          end
        end
      end

      def edit_with_easy_extensions
        @auth_sources = AuthSource.all
        @membership ||= Member.new
        if params[:tab] == 'my_page'
          if params[:tab_mode] == 'edit'
            render_action_as_easy_page(EasyPage.page_my_page, @user, nil, url_for(:action => 'edit', :id => @user.id, :tab => 'my_page', :t => params[:t]), true)
          elsif params[:tab_mode] == 'template'
          else
            render_action_as_easy_page(EasyPage.page_my_page, @user, nil, url_for(:action => 'edit', :id => @user.id, :tab => 'my_page', :t => params[:t]), false)
          end
        end
      end

      def update_with_easy_extensions
        if params[:user]
          @user.admin = params[:user][:admin] if params[:user][:admin]
          @user.login = params[:user][:login] if params[:user][:login]
          if params[:user][:password].present? && (@user.auth_source_id.nil? || params[:user][:auth_source_id].blank?)
            @user.password, @user.password_confirmation = params[:user][:password], params[:user][:password_confirmation]
          end
        end
        @user.safe_attributes = params[:user]
        # Was the account actived ? (do it before User#save clears the change)
        was_activated = (@user.status_change == [User::STATUS_REGISTERED, User::STATUS_ACTIVE])
        # TODO: Similar to My#account
        @user.pref.attributes = params[:pref]

        if @user.save
          @user.pref.save

          unless params[:page_template_id].blank?
            begin
              page_template = EasyPageTemplate.find(params[:page_template_id].to_i)
              EasyPageZoneModule.create_from_page_template(page_template, @user.id)
            rescue ActiveRecord::RecordNotFound
            end
          end

          unless params[:copy_roles_from].blank?
            source_user = User.find(params[:copy_roles_from]) rescue nil;
            @user.copy_roles_from(source_user) if source_user
          end

          if was_activated
            Mailer.account_activated(@user).deliver
          elsif @user.active? && params[:send_information] && @user.password.present? && @user.auth_source_id.nil?
            Mailer.account_information(@user, @user.password).deliver
          end

          respond_to do |format|
            format.html {
              flash[:notice] = l(:notice_successful_update)
              redirect_to :back
            }
            format.api  { render_api_ok}
          end
        else
          @auth_sources = AuthSource.all
          @membership ||= Member.new
          # Clear password input
          @user.password = @user.password_confirmation = nil

          respond_to do |format|
            format.html { render :action => :edit }
            format.api  { render_validation_errors(@user) }
          end
        end
      rescue ::ActionController::RedirectBackError
        redirect_to :controller => 'users', :action => 'edit', :id => @user
      end

      def edit_membership_with_easy_extensions
        if params[:membership]
          project_ids = params[:membership].delete(:project_ids) || []

          project_ids.each do |project_id|
            next if project_id.blank?
            unless Member.where(:user_id => params[:membership][:user_id], :project_id => project_id).exists?
              @membership = Member.edit_membership(params[:membership_id], params[:membership], @user)
              @membership.project_id = project_id unless project_id.blank?
              @membership.save
            end
          end
        end
        @membership ||= Member.edit_membership(params[:membership_id], params[:membership], @user)
        respond_to do |format|
          format.html { redirect_to edit_user_path(@user, :tab => 'memberships') }
          format.js
        end
      end

      def require_admin_with_easy_extensions
        require_admin_or_lesser_admin(:users)
      end

    end
  end

end
EasyExtensions::PatchManager.register_controller_patch 'UsersController', 'EasyPatch::UsersControllerPatch'
