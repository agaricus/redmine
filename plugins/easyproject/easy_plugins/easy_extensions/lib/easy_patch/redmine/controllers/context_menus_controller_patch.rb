module EasyPatch
  module ContextMenusControllerPatch

    def self.included(base)
      base.send(:include, InstanceMethods)

      base.class_eval do

        helper :projects

        before_render :time_entries_clear_activities, :only => :time_entries
        before_render :time_entries_add_issues, :only => :time_entries

        alias_method_chain :issues, :easy_extensions

        def versioned_attachments
          @att_v = Attachment.find(params[:ids]).first.versions.reverse unless params[:ids].blank?
          render :layout => false
        end

        def versions
          @project = Project.find(params[:project_id]) if params[:project_id]
          @versions = Version.visible.where(:id => params[:ids])

          if @versions.size == 1
            @version = @versions.first
          end

          @can = {
            :edit => User.current.allowed_to?(:manage_versions, @project, :global => true),
            :destroy => User.current.allowed_to?(:manage_versions, @project, :global => true)
          }
          render :layout => false
        end

        def easy_attendances
          @easy_attendances = EasyAttendance.includes([:user]).where(:id => params[:ids])
          @users = @easy_attendances.collect(&:user).uniq
          @user = @users.first if @users.count == 1
          perm = (@user == User.current && User.current.allowed_to?(:edit_own_easy_attendances, nil, :global => true)) || User.current.allowed_to?(:edit_easy_attendances, nil, :global => true)
          @can = {
            :edit => perm,
            :destroy => perm
          }
          render :layout => false
        end

        def admin_projects
          @projects = Project.where(:id => params[:ids]).all
          @project = @projects.first if @projects.count == 1
          statuses = @projects.collect(&:status).uniq

          if statuses.count == 1
            case statuses.pop
            when Project::STATUS_ACTIVE
              @all_active = true
            when Project::STATUS_CLOSED
              @all_closed = true
            when Project::STATUS_ARCHIVED
              @all_archived = true
            end
          end

          render :layout => false
        end

        def templates
          @templates = Project.templates.where(:id => params[:ids]).all
          @template = @templates.first if @templates.count == 1

          render :layout => false
        end

        def easy_rake_tasks
          @tasks = EasyRakeTask.where(:id => params[:ids]).all
          @task = @tasks.first if @tasks.count == 1
          @back_url = back_url

          render :layout => false
        end

        private

        def time_entries_clear_activities
          unless @projects.blank?
            @activities = [] if @projects.detect{|p| p.fixed_activity?}
          end
        end

        def time_entries_add_issues
          if @project
            @issues = @project.issues.visible.open.order(:subject).limit(25)
          end
        end

      end
    end

    module InstanceMethods

      def issues_with_easy_extensions
        if (@issues.size == 1)
          @issue = @issues.first
        end
        @issue_ids = @issues.map(&:id).sort

        @allowed_statuses = @issues.map(&:new_statuses_allowed_to).reduce(:&)

        if EasySetting.value(:close_subtask_after_parent)
          unselected_children_ids = []
          @issues.each do |issue|
            unselected_children_ids += issue.descendants.pluck(:id)
            unselected_children_ids -= [issue.id]
          end

          @subtasks_to_close = unselected_children_ids.uniq.size
        end

        if !@project.nil? && !@project.shared_versions.open.empty?
          @versions = @project.shared_versions.open.sort
        elsif @projects.size > 1
          @versions = @projects.collect{|p| p.shared_versions.open}.inject{|memo, v| memo & v}.sort
        end

        @can = {:edit => User.current.allowed_to?(:edit_issues, @projects) || (@issue && (User.current.allowed_to?(:edit_own_issue, @issue.project) && @issue.author.id == User.current.id)),
          :log_time => (@project && User.current.allowed_to?(:log_time, @project)),
          :update => (User.current.allowed_to?(:edit_issues, @projects) || (User.current.allowed_to?(:change_status, @projects) && !@allowed_statuses.blank?)),
          :move => (@project && User.current.allowed_to?(:move_issues, @project)),
          :copy => (@issue && @project.tracker_ids.include?(@issue.tracker_id) && User.current.allowed_to?(:add_issues, @project)),
          :delete => User.current.allowed_to?(:delete_issues, @projects)
        }

        @can[:edit_basic_attrs] = @can[:edit] || (@project && User.current.allowed_to?(:add_issue_notes, @project))

        if @can[:edit] && @issue && EasyIssueTimer.active?(@issue.project)
          timer = @issue.easy_issue_timers.where(:user_id => User.current.id).running.last
            @easy_issue_timer_setting = Hash.new
            if timer && !timer.paused?
              @easy_issue_timer_setting[:label] = l(:button_easy_issue_timer_stop)
              @easy_issue_timer_setting[:url] = easy_issue_timer_stop_path(@issue, :timer_id => timer)
              @easy_issue_timer_setting[:icon] = 'icon-checked-circle'
            else
              @easy_issue_timer_setting[:label] = l((timer.nil? ? :button_easy_issue_timer_play : :button_easy_issue_timer_resume))
              @easy_issue_timer_setting[:url] = easy_issue_timer_play_path(@issue, :timer_id => timer)
              @easy_issue_timer_setting[:icon] = 'icon-play'
            end
        end
        if @project
          if @issue
            @assignables = @issue.assignable_users
          else
            @assignables = @project.assignable_users
          end
          @trackers = @project.trackers
        else
          #when multiple projects, we only keep the intersection of each set
          @assignables = @projects.map(&:assignable_users).reduce(:&)
          @trackers = @projects.map(&:trackers).reduce(:&)
        end
        @versions = @projects.map {|p| p.shared_versions.open}.reduce(:&)

        @priorities = IssuePriority.active.reverse
        @back = back_url

        @options_by_custom_field = {}
        if @can[:edit]
          custom_fields = @issues.map(&:available_custom_fields).reduce(:&).select do |f|
            %w(bool list user version).include?(f.field_format) && !f.multiple?
          end
          custom_fields.each do |field|
            values = field.possible_values_options(@projects)
            if values.any?
              @options_by_custom_field[field] = values
            end
          end
        end

        @safe_attributes = @issues.map(&:safe_attribute_names).reduce(:&)

        if @safe_attributes.include?('author_id')
          @available_authors = User.active.non_system_flag.sorted
          @available_authors.push(@issue.author) if @issue && @issue.author
          @available_authors.uniq!
        end

        render :layout => false
      end

    end

  end

end
EasyExtensions::PatchManager.register_controller_patch 'ContextMenusController', 'EasyPatch::ContextMenusControllerPatch'
