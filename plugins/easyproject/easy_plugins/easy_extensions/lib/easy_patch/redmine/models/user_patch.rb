module EasyPatch
  module UserPatch

    def self.included(base)
      base.extend(ClassMethods)
      base.send(:include, InstanceMethods)

      base.class_eval do

        const_set(:EASY_USER_TYPE_INTERNAL, 1)
        const_set(:EASY_USER_TYPE_EXTERNAL, 2)

        has_and_belongs_to_many :favorite_projects,
          :class_name => 'Project',
          :join_table => "#{table_name_prefix}favorite_projects#{table_name_suffix}",
          :uniq => true

        has_many :easy_invitations
        has_many :invited_to_meetings, :class_name => 'EasyMeeting', :through => :easy_invitations, :source => :easy_meeting
        has_one :working_time_calendar, :class_name => 'EasyUserWorkingTimeCalendar', :foreign_key => 'user_id', :dependent => :destroy
        has_many :easy_attendances, :dependent => :destroy
        has_many :easy_page_tabs, :class_name => 'EasyPageUserTab', :foreign_key => 'user_id', :dependent => :destroy
        has_many :assigned_issues, :class_name => 'Issue', :foreign_key => 'assigned_to_id'
        has_many :roles, :through => :members, :uniq => true, :order => "#{Role.table_name}.position"

        has_many :easy_issue_timers, :dependent => :destroy
        has_many :easy_attendance_user_arrival_notifies, :dependent => :destroy

        has_many :easy_sliding_panels_locations, :dependent => :destroy

        has_one :avatar, :class_name => 'Attachment', :as  => :container, :conditions => {:attachments => {:description => 'avatar'}}, :dependent => :destroy

        after_create :create_my_page_from_page_template
        after_create :create_easy_user_working_time_calendar_from_default
        after_create :create_user_tokens

        acts_as_attachable

        remove_validation :login, 'validates_length_of'
        validates_length_of :login, :maximum => 255

        validate :validate_tokens

        attr_reader :rss_key_error
        attr_reader :api_key_error
        attr_accessor :in_mobile_view

        serialize :easy_lesser_admin_permissions, Array

        safe_attributes 'rss_key', 'api_key'

        safe_attributes 'easy_system_flag', 'easy_user_type',
          :if => lambda {|user, current_user| current_user.admin? || current_user.easy_lesser_admin?}

        safe_attributes 'admin', 'easy_lesser_admin', 'easy_lesser_admin_permissions',
          :if => lambda {|user, current_user| current_user.admin?}


        scope :easy_type_internal, lambda { where(:easy_user_type => User::EASY_USER_TYPE_INTERNAL) }
        scope :easy_type_external, lambda { where(:easy_user_type => User::EASY_USER_TYPE_EXTERNAL) }

        alias_method_chain :allowed_to?, :easy_extensions
        alias_method_chain :cache_key, :easy_extensions
        alias_method_chain :notify_about?, :easy_extensions
        alias_method_chain :projects_by_role, :easy_extensions
        alias_method_chain :remove_references_before_destroy, :easy_extensions

        class << self

          alias_method_chain :valid_notification_options, :easy_extensions

        end

        def <=>(user)
          self.name <=> user.name
        end

        def project
          nil
        end

        def rss_key=(key)
          @rss_key_error = self.rss_token.update_attributes(:value => key)
        end

        def api_key=(key)
          @api_key_error = self.api_token.update_attributes(:value => key)
        end

        def validate_tokens
          errors.add(:rss_key, :invalid) if @rss_key_error == false
          errors.add(:api_key, :invalid) if @api_key_error == false
        end

        def user_time_entry_setting
          self.pref.user_time_entry_setting.nil? ? :hours : self.pref.user_time_entry_setting.to_sym
        end

        def user_time_entry_setting_hours?
          (self.user_time_entry_setting == :hours) || (self.user_time_entry_setting == :all)
        end

        def user_time_entry_setting_range?
          (self.user_time_entry_setting == :range) || (self.user_time_entry_setting == :all)
        end

        def current_working_time_calendar
          return @current_working_time_calendar if @current_working_time_calendar

          @current_working_time_calendar = self.working_time_calendar
          if @current_working_time_calendar.nil?
            create_easy_user_working_time_calendar_from_default
            reload
            @current_working_time_calendar = self.working_time_calendar
          end
          @current_working_time_calendar
        end

        def working_hours(date = nil)
          return 8.0 unless date.is_a?(Date)

          non_working_attendance = self.easy_attendances.non_working.between(date, date).sum_spent_time(self.current_working_time_calendar, true)
          non_working_attendance ||= 0.0

          wc_hours = self.current_working_time_calendar.working_hours(date) if self.current_working_time_calendar
          wc_hours ||= 8.0

          if wc_hours > 0.0 && non_working_attendance > 0.0
            if wc_hours > non_working_attendance
              wc_hours - non_working_attendance
            else
              0.0
            end
          else
            wc_hours
          end
        end

        def working_hours_between(day_from = nil, day_to = nil)
          day_from ||= Date.today
          day_to ||= Date.today

          default_working_hours = self.current_working_time_calendar.default_working_hours if self.current_working_time_calendar
          default_working_hours ||= 8.0
          half_working_hours = default_working_hours / 2

          h = {}
          non_working_attendance = self.easy_attendances.non_working.between(day_from, day_to).get_spent_time(default_working_hours, half_working_hours, true)
          if non_working_attendance
            non_working_attendance.each do |day, hours|
              if hours == 0.0
                h[day] ||= default_working_hours
              elsif hours <= half_working_hours
                h[day] ||= half_working_hours
              else
                h[day] ||= 0.0
              end
            end
          end

          wc_hours = self.current_working_time_calendar.working_hours_between(day_from, day_to) if self.current_working_time_calendar
          if wc_hours
            wc_hours.each do |day, hours|
              h[day] ||= hours
            end
          end

          day_from.upto(day_to) do |day|
            h[day] ||= 0.0
          end

          h
        end

        def limit_assignable_users_for_project?(project)
          project && roles_for_project(project).select(&:limit_assignable_users).any?
        end

        def copy_roles_from(source_user)
          return if self.new_record? || !source_user.is_a?(User) || source_user.new_record?

          Member.find(:all, :conditions => {:user_id => self.id}).each(&:destroy)

          projects_and_roles = MemberRole.find(:all, :include => :member, :conditions => {:members=>{:user_id => source_user.id}, :inherited_from => nil}).group_by{|mr| mr.member.project_id}

          projects_and_roles.each do |member_project_id, member_roles|
            Member.create(:role_ids => member_roles.collect(&:role_id), :user_id => self.id, :project_id => member_project_id)
          end
        end

        def get_easy_attendance_last_arrival
          return self.easy_attendances.where("#{EasyAttendance.table_name}.departure IS NULL").last
        end

        def get_easy_attendance_last_departure
          return self.easy_attendances.where("#{EasyAttendance.table_name}.departure IS NOT NULL").last
        end

        def get_easy_attendance_yesterday_departure
          return self.easy_attendances.where(["(#{EasyAttendance.table_name}.departure BETWEEN ? AND ? )", DateTime.yesterday.beginning_of_day, DateTime.yesterday.end_of_day]).last
        end

        def empty_today_attendance?
          @empty_today_attendance ||= self.easy_attendances.where(["#{EasyAttendance.table_name}.arrival BETWEEN ? AND ?", self.user_time_in_zone.beginning_of_day, self.user_time_in_zone.end_of_day]).count == 0
        end

        def is_in_work?
          return @is_in_work unless @is_in_work.nil?
          if last_today_attendance
            @is_in_work = last_today_attendance.departure.nil?
          else
            @is_in_work = false
          end

          return @is_in_work
        end

        def last_today_attendance
          @last_today_attendance ||= self.easy_attendances.joins(:easy_attendance_activity).where(:easy_attendances => {:arrival => Time.now.beginning_of_day..Time.now.end_of_day}).last
        end

        def in_mobile_view?
          return self.in_mobile_view
        end

        def user_time_in_zone(time=nil)
          time ||= Time.now
          if self.time_zone.nil?
            return time.localtime
          else
            return time.in_time_zone(self.time_zone)
          end
        end

        def current_theme
          return @current_theme if @current_theme
          @current_theme = Redmine::Themes.theme(self.pref[:user_theme]) if EasySetting.value('use_personal_theme')
          @current_theme ||= Redmine::Themes.theme(Setting.ui_theme)
        end

        def current_theme_is_easy?
          current_theme && current_theme.is_easy_theme?
        end

        def easy_lesser_admin_for?(area_name)
          return true if self.admin?
          return false if !respond_to?(:easy_lesser_admin)
          return false if !self.easy_lesser_admin?
          return true if area_name.blank?
          return false if self.easy_lesser_admin_permissions.blank?

          !!self.easy_lesser_admin_permissions.detect{|p| p.to_s == area_name.to_s}
        end

        def internal_client?
          self.easy_user_type == User::EASY_USER_TYPE_INTERNAL
        end

        def external_client?
          self.easy_user_type == User::EASY_USER_TYPE_EXTERNAL
        end

        def allowed_to_at_least_one_action?(actions, project)
          actions.each do |action|
            if self.allowed_to?(action, project)
              return true
            end
          end
          false
        end

        private

        def create_my_page_from_page_template
          if EasyPage.table_exists? && EasyPageTemplate.table_exists? && EasyPageZoneModule.table_exists?
            my_page = EasyPage.find(:first, :conditions => {:page_name => 'my-page'})
            if my_page
              my_page_template = EasyPageTemplate.default_template_for_page(my_page)
              if my_page_template
                EasyPageZoneModule.create_from_page_template(my_page_template, self.id, nil)
              end
            end
          end
        end

        def create_easy_user_working_time_calendar_from_default
          return unless EasyUserWorkingTimeCalendar.table_exists?

          default_calendar = EasyUserWorkingTimeCalendar.where(:user_id => nil, :parent_id => nil, :is_default => true).first
          default_calendar ||= EasyUserWorkingTimeCalendar.where(:user_id => nil, :parent_id => nil, :builtin => true).first
          default_calendar ||= EasyUserWorkingTimeCalendar.where(:user_id => nil, :parent_id => nil).first

          default_calendar.assign_to_user(self, true) if default_calendar
        end

        def create_user_tokens
          self.rss_key
          self.api_key
        end

      end
    end

    module InstanceMethods

      def cache_key_with_easy_extensions
        if new_record?
          'users/new'
        else
          "users/#{id}-#{updated_on.strftime('%Y%m%d%H%M%S')}"
        end
      end

      def projects_by_role_with_easy_extensions
        return @projects_by_role if @projects_by_role

        @projects_by_role = Hash.new {|h,k| h[k]=[]}

        Role.all.each do |role|
          role_members = role.members.includes(:project).where(:user_id => self.id).all
          if role_members.any?
            @projects_by_role[role] = role_members.collect{|rm| rm.project}
          end
        end

        @projects_by_role
      end

      def allowed_to_with_easy_extensions?(action, context, options={}, &block)
        options ||= {}
        ignore_admin = options[:ignore_admin] || false
        if context && context.is_a?(Project)
          return false unless context.allows_to?(action)
          if context.easy_is_easy_template?
            return self.allowed_to?(action, nil, options.merge({:global => true}), &block)
          end
          # Admin users are authorized for anything else
          return true if admin? && !ignore_admin

          rfp = roles_for_project(context)
          return false unless rfp
          rfp.any? {|role|
            (context.is_public? || role.member?) &&
              role.allowed_to?(action) &&
              (block_given? ? yield(role, self) : true)
          }
        elsif context && context.is_a?(Array)
          if context.empty?
            false
          else
            # Authorize if user is authorized on every element of the array
            context.map {|project| allowed_to?(action, project, options, &block)}.reduce(:&)
          end
        elsif options[:global]
          # Admin users are always authorized
          return true if admin? && !ignore_admin

          # authorize if user has at least one role that has this permission
          all_roles = self.roles.all
          all_roles << (self.logged? ? Role.non_member : Role.anonymous)
          all_roles.any? {|role|
            role.allowed_to?(action) &&
              (block_given? ? yield(role, self) : true)
          }
        else
          false
        end
      end

      def notify_about_with_easy_extensions?(object)
        n = notify_about_without_easy_extensions?(object)

        if n && object.is_a?(Issue) && self.pref[:no_notified_if_issue_closing] == true && object.status.is_closed?
          n = false
        end

        n
      end

      def remove_references_before_destroy_with_easy_extensions
        remove_references_before_destroy_without_easy_extensions

      end
    end

    module ClassMethods

      def valid_notification_options_with_easy_extensions(user=nil)
        if user.nil? || user.new_record? || Project.visible(user).size < 1
          User::MAIL_NOTIFICATION_OPTIONS.reject {|option| option.first == 'selected'}
        else
          User::MAIL_NOTIFICATION_OPTIONS
        end
      end

    end

  end

end
EasyExtensions::PatchManager.register_model_patch 'User', 'EasyPatch::UserPatch'
