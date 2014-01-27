module EasyPatch
  module UsersHelperPatch

    def self.included(base)
      base.send(:include, InstanceMethods)

      base.class_eval do

        alias_method_chain :user_settings_tabs, :easy_extensions
        alias_method_chain :change_status_link, :easy_extensions

        def user_show_tabs
          tabs = [{:name => 'general_show', :partial => 'users/show', :label => :label_general, :no_js_link => true}]
          call_hook(:helper_user_show_tabs, :user => @user, :tabs => tabs)
          tabs
        end

        def render_api_principal(api, principal)
          if principal.is_a?(User)
            render_api_user(api, principal)
          elsif principal.is_a?(Group)
            render_api_group(api, principal)
          end
        end

        def render_api_user(api, user, memberships = nil)
          api.user do
            api.id(user.id)
            api.login(user.login) if User.current.admin? || (User.current == user)
            api.firstname(user.firstname)
            api.lastname(user.lastname)
            api.mail(user.mail) if User.current.admin? || !user.pref.hide_mail
            api.created_on(user.created_on)
            api.last_login_on(user.last_login_on)
            api.api_key(user.api_key) if User.current.admin? || (User.current == user)
            api.status(user.status) if User.current.admin?

            api.array :tokens do
              api.token do
                api.action user.api_token.action
                api.value user.api_token.value
              end if user.api_token
              api.token do
                api.action user.rss_token.action
                api.value user.rss_token.value
              end if user.rss_token
            end if (User.current.admin? || User.current == user)

            render_api_custom_values(user.visible_custom_field_values, api)

            api.array :memberships do
              memberships.each do |membership|
                api.membership do
                  api.project :id => membership.project.id, :name => membership.project.name
                  api.array :roles do
                    membership.roles.each do |role|
                      api.role :id => role.id, :name => role.name
                    end
                  end
                end if membership.project
              end
            end if include_in_api_response?('memberships') && memberships
          end
        end

        def render_api_group(api, group)
          api.group do
            api.id(group.id)
            api.lastname(group.lastname)
            api.created_on(group.created_on)

            render_api_custom_values(group.visible_custom_field_values, api)
          end
        end

        def easy_user_query_additional_ending_buttons(user, options= {})
          links = Array.new
          links << link_to(l(:button_show),{:controller => 'users', :action => 'show', :id => user}, :class => 'icon icon-user', :title => l(:button_view), :alt => l(:button_view))
          links << link_to(l(:button_edit),{:controller => 'users', :action => 'edit', :id => user}, :class => 'icon icon-edit', :title => l(:button_edit), :alt => l(:button_edit))
          links << change_status_link(user)
          links << link_to(l(:button_delete), {:controller => 'users', :action => 'destroy', :id => user}, :data => {:confirm => l(:text_are_you_sure)}, :method => :delete, :class => 'icon icon-del') unless User.current == user

          return links.join.html_safe
        end

        def easy_user_type_options
          [[l(:'user.easy_user_type.internal'), User::EASY_USER_TYPE_INTERNAL], [l(:'user.easy_user_type.external'), User::EASY_USER_TYPE_EXTERNAL]]
        end

        def easy_lesser_admin_permissions
          list = [
            [l(:label_user_plural), :users], [l(:label_group_plural), :groups], [l(:label_admin_easy_user_working_time_calendars), :working_time],
            [l(:label_role_and_permissions), :roles], [l(:label_tracker_plural), :trackers], [l(:label_issue_status_plural), :issue_statuses]
          ]

          ctx = {:list => list}
          Redmine::Hook.call_hook(:helper_users_easy_lesser_admin_permissions, ctx)

          ctx[:list]
        end

      end
    end

    module InstanceMethods

      def change_status_link_with_easy_extensions(user, options={})
        link = change_status_link_without_easy_extensions(user)
        if !EasyLicenseManager.has_license_limit?(:user_limit) && user.locked?
          link = content_tag(:span, l('license_manager.user_limit_unlock_button'), :style => 'color: red')
        end
        return link
      end

      def user_settings_tabs_with_easy_extensions
        tabs = [{:name => 'general', :partial => 'users/general', :label => :label_general, :no_js_link => true},
          {:name => 'memberships', :partial => 'users/memberships', :label => :label_project_plural, :no_js_link => true},
          {:name => 'working_time', :partial => 'users/working_time', :label => :label_working_time, :user => @user, :no_js_link => true}
        ]
        if Group.all.any?
          tabs.insert 1, {:name => 'groups', :partial => 'users/groups', :label => :label_group_plural, :no_js_link => true}
        end
        tabs << {:name => 'avatar', :partial => 'easy_avatars/avatar', :label => :label_avatar, :no_js_link => true, :user => @user}
        tabs << {:name => 'my_page', :partial => 'easy_page_modules_tabs', :label => :label_user_my_page, :user => @user, :page => EasyPage.page_my_page, :no_js_link => true}
        call_hook(:helper_user_settings_tabs, :user => @user, :tabs => tabs)
        tabs
      end

    end
  end
end
EasyExtensions::PatchManager.register_helper_patch 'UsersHelper', 'EasyPatch::UsersHelperPatch'
