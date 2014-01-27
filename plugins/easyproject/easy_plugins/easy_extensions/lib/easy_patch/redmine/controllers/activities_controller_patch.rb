module EasyPatch
  module ActivitiesControllerPatch

    def self.included(base)
      base.send(:include, InstanceMethods)
      base.class_eval do

        alias_method_chain :index, :easy_extensions

        before_render :settings_before_render , :only => :index

        private

        def settings_before_render
          disabled_features = EasyExtensions::EasyProjectSettings.disabled_features[:modules] - ['easy_attendances']
          @activity.event_types.delete_if{|i| disabled_features.include?(i)} if @activity
        end
      end
    end

    module InstanceMethods

      def index_with_easy_extensions
        @days = Setting.activity_days_default.to_i

        if params[:from]
          begin; @date_to = params[:from].to_date + 1; rescue; end
        end

        @date_to ||= Date.today + 1
        @date_from = @date_to - @days
        @with_subprojects = params[:with_subprojects].nil? ? Setting.display_subprojects_issues? : (params[:with_subprojects] == '1')
        @author = (params[:user_id].blank? ? nil : User.active.find(params[:user_id]))

        @activity = Redmine::Activity::Fetcher.new(User.current, :project => @project,
                                                                 :with_subprojects => @with_subprojects,
                                                                 :author => @author)
        @activity.scope_select {|t| !params["show_#{t}"].nil?}
        if EasySetting.value('default_activity_in_overall_activity').any?
          @activity.scope = EasySetting.value('default_activity_in_overall_activity')
        else
          @activity.scope = (@author.nil? ? :default : :all) if @activity.scope.empty?
        end

        events = @activity.events(@date_from, @date_to)

        if events.empty? || stale?(:etag => [@activity.scope, @date_to, @date_from, @with_subprojects, @author, events.first, events.size, User.current, current_language])
          respond_to do |format|
            format.html {
              @events_by_day = events.group_by {|event| User.current.time_to_date(event.event_datetime)}
              render :layout => false if request.xhr?
            }
            format.atom {
              title = l(:label_activity)
              if @author
                title = @author.name
              elsif @activity.scope.size == 1
                title = l("label_#{@activity.scope.first.singularize}_plural")
              end
              render_feed(events, :title => "#{@project || Setting.app_title}: #{title}")
            }
          end
        end
      rescue ActiveRecord::RecordNotFound
        render_404
      end

    end

  end
end
EasyExtensions::PatchManager.register_controller_patch 'ActivitiesController', 'EasyPatch::ActivitiesControllerPatch'
