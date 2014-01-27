module EasyPatch
  module WatchersControllerPatch

    def self.included(base)
      base.send(:include, InstanceMethods)

      base.class_eval do

        before_filter :get_available_watchers, :only => [:new, :autocomplete_for_user]
        skip_before_filter :find_project, :only => [:toggle_members]

        alias_method_chain :autocomplete_for_user, :easy_extensions
        alias_method_chain :new, :easy_extensions

        def toggle_members
          group = Group.find(params[:group_id])
          user_fields = group.users.map{|user| "watcher_user_ids_#{user.id}"}
          render :js => "fields = #{user_fields.to_json}; toggleCheckbox('watcher_user_groups_#{group.id}'); $(fields).each(function(f) {toggleCheckbox(fields[f])})"
        end

        private

        def get_available_watchers
          @available_watchers = if @watched
            @watched.addable_watcher_users
          else
            User.member_of(@project)
          end
        end
      end
    end

    module InstanceMethods

      def autocomplete_for_user_with_easy_extensions
        unless params[:reset]
          if @watched
            @users = @watched.project.users.non_system_flag.sorted.like(params[:easy_query_q]).limit(100).all
            @users -= @watched.watcher_users
          end
        end
        render(:partial => 'watchers/new', :locals => {:watched => @watched, :available_watchers => @users || @available_watchers} )
      end

      def new_with_easy_extensions
        respond_to do |format|
          format.js
        end
      end
    end

  end
end
EasyExtensions::PatchManager.register_controller_patch 'WatchersController', 'EasyPatch::WatchersControllerPatch'
