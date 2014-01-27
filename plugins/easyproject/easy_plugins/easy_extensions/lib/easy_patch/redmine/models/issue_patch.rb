module EasyPatch
  module IssuePatch

    def self.included(base)
      base.extend(ClassMethods)
      base.send(:include, InstanceMethods)

      base.class_eval do

        belongs_to :activity, :class_name => 'TimeEntryActivity', :foreign_key => 'activity_id'
        has_many :easy_issue_timers, :dependent => :destroy

        html_fragment :description, :scrub => :strip

        searchable_options[:additional_conditions] = "#{Project.table_name}.easy_is_easy_template = #{connection.quoted_false}"
        searchable_options[:include] << :attachments
        searchable_options[:column_types] = {
          :names => ["#{table_name}.subject"],
          :descriptions => ["#{table_name}.description"],
          :comments => ["#{Journal.table_name}.notes"],
          :others => ["#{Attachment.table_name}.filename"]
        }

        event_options[:title] = Proc.new{|issue| "#{issue.tracker}: #{Sanitize.clean(issue.subject || '', :output => :html)}"}

        acts_as_easy_journalized :non_journalized_columns => ['id', 'root_id', 'lft', 'rgt', 'lock_version', 'created_on', 'updated_on'],
          :format_detail_boolean_columns => ['easy_is_repeating']

        include EasyPatch::Acts::Repeatable
        acts_as_easy_repeatable

        attr_reader :issue_move_to_project_errors
        attr_accessor :relation, :mass_operations_in_progress, :send_to_external_mails, :attributes_for_descendants
        attr_reader :should_send_invitation_update

        safe_attributes 'author_id',
          :if => lambda {|issue, user| issue.new_record? || user.allowed_to?(:edit_issues, issue.project) }
        safe_attributes 'activity_id',
          :if => lambda {|issue, user| issue.project && issue.project.fixed_activity? }
        safe_attributes 'relation'
        safe_attributes 'send_to_external_mails'

        delete_safe_attribute 'custom_field_values'
        safe_attributes 'custom_field_values' # TODO - osetrit jen na custom fieldy, kteri maji show_on_more_field == false

        delete_safe_attribute 'watcher_user_ids'
        safe_attributes 'watcher_user_ids',
          :if => lambda {|issue, user| user.allowed_to?(:add_issue_watchers, issue.project)}

        safe_attributes 'easy_start_date_time'
        safe_attributes 'easy_due_date_time'

        before_validation :create_issue_relations
        after_move :set_easy_level
        after_create :set_easy_level
        after_save :move_fixed_version_effective_date_if_needed
        after_save :close_children, :if => Proc.new{|issue| EasySetting.value(:close_subtask_after_parent)}
        before_save :set_percent_done, :ensure_easy_issue_timer

        validates_presence_of :activity_id, :if => Proc.new { |issue| issue.project && issue.project.fixed_activity? && issue.new_record? }
        validate :validate_do_not_allow_close_if_subtasks_opened
        validate :validate_do_not_allow_close_if_no_attachments
        validate :validate_estimated_hours
        validates_presence_of :due_date, :if => Proc.new { |issue| issue.tracker && issue.tracker.easy_is_meeting? }

        scope :non_templates, lambda { { :conditions => "#{Project.table_name}.easy_is_easy_template = #{connection.quoted_false}", :include => :project } }

        alias_method_chain :after_create_from_copy, :easy_extensions
        alias_method_chain :assignable_users, :easy_extensions
        alias_method_chain :cache_key, :easy_extensions
        alias_method_chain :create_journal, :easy_extensions
        alias_method_chain :css_classes, :easy_extensions
        alias_method_chain :copy_from, :easy_extensions
        alias_method_chain :editable?, :easy_extensions
        alias_method_chain :estimated_hours=, :easy_extensions
        alias_method_chain :new_statuses_allowed_to, :easy_extensions
        alias_method_chain :notified_users, :easy_extensions
        alias_method_chain :overdue?, :easy_extensions
        alias_method_chain :recalculate_attributes_for, :easy_extensions
        alias_method_chain :relations, :easy_extensions
        alias_method_chain :reschedule_on!, :easy_extensions
        alias_method_chain :safe_attributes=, :easy_extensions
        alias_method_chain :send_notification, :easy_extensions
        alias_method_chain :to_s, :easy_extensions
        alias_method_chain :validate_issue, :easy_extensions
        alias_method_chain :visible?, :easy_extensions
        alias_method_chain :workflow_rule_by_attribute, :easy_extensions

        class << self

          alias_method_chain :visible_condition, :easy_extensions
          alias_method_chain :allowed_target_projects_on_move, :easy_extensions

          def by_custom_field(cf, project)
            count_and_group_by_custom_field(cf, {:project => project})
          end

          def by_custom_fields(project)
            left_reported_cf = Hash.new
            right_reported_cf = Hash.new
            (IssueCustomField.where(:is_for_all => true, :field_format => 'list') + project.issue_custom_fields.where(:field_format => 'list')).uniq.each_with_index do |i, index|
              data = {
                :reports => by_custom_field(i, project),
                :name => i.name
              }
              if index.even?
                left_reported_cf["cf_#{i.id}"] = data
              else
                right_reported_cf["cf_#{i.id}"] = data
              end
            end

            return left_reported_cf, right_reported_cf
          end

          def by_unassigned_to(project)
            ActiveRecord::Base.connection.select_all("SELECT
           s.id AS status_id,
           s.is_closed AS closed,
           NULL AS assigned_to_id,
           count(issues.id)AS total
           FROM
           #{Issue.table_name},
           #{Project.table_name},
           #{IssueStatus.table_name} s
           WHERE
           #{Issue.table_name}.status_id = s.id
           AND #{Issue.table_name}.assigned_to_id IS NULL
           AND #{Issue.table_name}.project_id = #{Project.table_name}.id
           and #{visible_condition(User.current, :project => project)}
           GROUP BY
           s.id,
           s.is_closed")
          end

          def update_from_gantt(data)
            unsaved_issues = []
            unsaved_versions = []
            possible_unsaved_issue = nil
            possible_unsaved_version = nil
            (data['projects']['project']['task'].kind_of?(Array) ? data['projects']['project']['task'] : [data['projects']['project']['task']]).each do |gantt_data|
              if gantt_data['childtasks']
                # milestone
                possible_unsaved_version = Version.update_version_from_gantt_data(gantt_data)
                unsaved_versions << possible_unsaved_version if possible_unsaved_version
                (gantt_data['childtasks']['task'].kind_of?(Array) ? gantt_data['childtasks']['task'] : [gantt_data['childtasks']['task']]).each do |child_data|
                  possible_unsaved_issue = self.update_issue_from_gantt_data(child_data)
                  unsaved_issues << possible_unsaved_issue if possible_unsaved_issue
                end
              else
                possible_unsaved_issue = self.update_issue_from_gantt_data(gantt_data)
                unsaved_issues << possible_unsaved_issue if possible_unsaved_issue
              end
            end
            {:unsaved_issues => unsaved_issues, :unsaved_versions => unsaved_versions}
          end

          private

          def parse_gantt_date(date_string)
            if date_string.match('\d{4},\d{1,2},\d{1,2}')
              Date.strptime(date_string, '%Y,%m,%d')
            end
          end

          def count_and_group_by_custom_field(cf, options)
            project = options.delete(:project)
            ActiveRecord::Base.connection.select_all("
              SELECT s.id as status_id, s.is_closed as closed, j.value as cf_#{cf.id}, count(#{Issue.table_name}.id) as total
              FROM #{Issue.table_name}
              JOIN #{CustomValue.table_name} j ON j.customized_id = #{Issue.table_name}.id AND j.customized_type = 'Issue'
              JOIN #{Project.table_name} ON #{Project.table_name}.id = #{Issue.table_name}.project_id
              JOIN #{IssueStatus.table_name} s ON s.id = #{Issue.table_name}.status_id
              WHERE
              j.custom_field_id = #{cf.id}
              AND #{Issue.visible_condition(User.current, :project => project)}
              GROUP BY s.id, s.is_closed, j.value
              ")
          end

        end

        def parent_issue
          @parent_issue
        end

        def set_easy_level(level=self.level)
          return unless self.class.columns.detect{|c| c.name == 'easy_level'}
          update_column(:easy_level, level)
          Issue.where(:parent_id => id).each{|i| i.set_easy_level(level + 1)}
        end

        def parent_project
          @parent_project ||= self.project.parent_project if self.project
        end

        def main_project
          @main_project ||= self.project.main_project if self.project
        end

        def sum_of_timeentries
          if EasySetting.value('issue_recalculate_attributes', self.project)
            @sum_of_timeentries ||= self.total_spent_hours
          else
            @sum_of_timeentries ||= self.time_entries.sum(:hours)
          end
        end

        def remaining_timeentries
          @remaining_timeentries ||= ((self.estimated_hours || 0.0) - self.sum_of_timeentries)
        end

        def spent_estimated_timeentries
          @spent_estimated_timeentries ||= begin
            if self.estimated_hours && self.estimated_hours > 0
              ((self.sum_of_timeentries / self.estimated_hours) * 100).to_i
            else
              0
            end
          end
        end

        def last_user_assigned_to
          last_assigned_to = nil
          journals_details = self.journals.includes(:details).order('created_on DESC').all.collect{|j| j.details.detect{|d| d.prop_key == 'assigned_to_id'}}.compact
          if journals_details.any?
            last_assigned_to = Principal.find(journals_details.first.old_value) if journals_details.first.old_value && journals_details.first.old_value.to_i > 0
          else
            last_assigned_to = self.assigned_to if last_assigned_to.nil?
          end
          last_assigned_to
        end

        def build_issue_relations_from_params(params)
          if params && params['issue_to_id'] && params['issue_to_id']
            [params['issue_to_id']].flatten.each do |issue_to_id|
              issue_to = Issue.find_by_id(issue_to_id)
              relations_from.build(:relation_type => params['relation_type'], :delay => params['relation_delay'], :issue_from => self, :issue_to => issue_to) if issue_to
            end
          end
        end

        def to_s_with_id
          suffix = self.easy_is_repeating? ? (' ' + l(:label_easy_issue_subject_reccuring_suffix)) : ''
          "##{self.id} - #{self.subject}#{suffix}"
        end

        def to_s_without_id
          suffix = self.easy_is_repeating? ? (' ' + l(:label_easy_issue_subject_reccuring_suffix)) : ''
          "#{self.subject}#{suffix}"
        end

        def get_notified_users_for_mail(type = :all, journal = nil)
          if self.assigned_to
            assigned_notified_users = (self.assigned_to.is_a?(Group) ? self.assigned_to.users : [self.assigned_to]).select{|u| u.active? && u.notify_about?(self)}
          else
            assigned_notified_users = []
          end
          if journal
            assigned_notified_users = (assigned_notified_users & journal.notified_users)
          end

          case type
          when :all
            issue_notified_users = journal.nil? ? self.notified_users : journal.notified_users
            issue_notified_watchers = (self.notified_watchers - issue_notified_users)
          when :assigned_to
            issue_notified_users = assigned_notified_users
            issue_notified_watchers = []
          when :except_assigned_to
            issue_notified_users = []
            if journal
              issue_notified_watchers = (journal.notified_users | journal.notified_watchers) - assigned_notified_users
            else
              issue_notified_watchers = (self.notified_users | self.notified_watchers) - assigned_notified_users
            end
          end

          {:to => issue_notified_users, :cc => issue_notified_watchers}
        end

        def get_notified_mails_for_mail(type = :all, journal = nil)
          users = get_notified_users_for_mail(type, journal)
          {:to => users[:to].collect(&:mail), :cc => users[:cc].collect(&:mail)}
        end

        def get_notified_users_for_mail_grouped_by_lang(type = :all, journal = nil)
          users_to_notify = self.get_notified_users_for_mail(type, journal)

          users_to_notify_to = users_to_notify[:to]
          users_to_notify_cc = users_to_notify[:cc]

          users_to_notify_to_by_lang = users_to_notify_to.inject({}){|memo, u| memo[u.language] ||= []; memo[u.language] << u.mail; memo}
          users_to_notify_cc_by_lang = users_to_notify_cc.inject({}){|memo, u| memo[u.language] ||= []; memo[u.language] << u.mail; memo}

          {:to => users_to_notify_to_by_lang, :cc => users_to_notify_cc_by_lang}
        end

        private

        def close_children
          if self.closed? && self.children.any?
            self.descendants.update_all(:status_id => self.status_id)
          end
        end

        def create_issue_relations
          build_issue_relations_from_params(relation) if new_record?
        end

        def validate_do_not_allow_close_if_subtasks_opened
          return if self.tracker.nil? || !self.tracker.respond_to?(:easy_do_not_allow_close_if_subtasks_opened)
          return if self.leaf? || !self.status || !self.status.is_closed?
          return unless self.tracker.easy_do_not_allow_close_if_subtasks_opened?

          unclosed = self.descendants.where(["#{IssueStatus.table_name}.is_closed = ?", false]).includes(:status)

          return if unclosed.count == 0

          errors.add :base, l(:error_cannot_close_issue_due_to_subtasks, :issues => ('<br />' + unclosed.all.collect{|i| i.to_s}.join('<br />'))).html_safe
        end

        def validate_do_not_allow_close_if_no_attachments
          return if !self.tracker || !self.tracker.respond_to?(:easy_do_not_allow_close_if_no_attachments)
          return if !self.status || !self.status.is_closed?
          return unless self.tracker.easy_do_not_allow_close_if_no_attachments?
          return if self.attachments.size > 0

          errors.add :base, l(:error_cannot_close_issue_due_to_no_attachments)
        end

        def validate_estimated_hours
          if self.due_date && self.start_date && self.estimated_hours
            if ((self.duration + 1) * 24 + (self.sum_of_timeentries || 0.0)) < self.estimated_hours
              errors.add :due_date, :less_than_duration
            end
          end
        end


        def move_fixed_version_effective_date_if_needed
          if EasySetting.value('milestone_effective_date_from_issue_due_date') && self.fixed_version && self.fixed_version.effective_date && self.due_date
            if self.fixed_version.effective_date < self.due_date
              journal = self.fixed_version.init_journal(User.current, l(:text_milestone_effective_date_from_issue, :issue => self.id))
              self.fixed_version.update_attributes(:effective_date => self.due_date)
            end
          end
        end

        def ensure_easy_issue_timer
          if self.closed? || self.status_id_changed? || self.assigned_to_id_changed?
            self.easy_issue_timers.where(:user_id => self.assigned_to_id_was).delete_all
          end
        end

        def set_percent_done
          return if !EasySetting.value('issue_set_done_after_close')
          return if self.done_ratio == 100

          if self.status_id_changed? && self.status && self.status.is_closed?
            self.done_ratio = 100
          end
        end

        def reformat_meeting_datetime_attributes(attrs)
          return unless attrs.is_a?(Hash) && self.tracker && self.tracker.easy_is_meeting?

          start_date_time = begin Time.parse(attrs[:start_date]) rescue Time.now end
          end_date_time = begin Time.parse(attrs[:due_date]) rescue Time.now end

          start_date_time = start_date_time.change(:hour => attrs[:easy_start_date_time][:hour], :min => attrs[:easy_start_date_time][:minute]) if attrs[:easy_start_date_time].is_a?(Hash)
          end_date_time = end_date_time.change(:hour => attrs[:easy_due_date_time][:hour], :min => attrs[:easy_due_date_time][:minute]) if attrs[:easy_due_date_time].is_a?(Hash)

          attrs[:easy_start_date_time] = start_date_time
          attrs[:easy_due_date_time] = end_date_time
        end

      end
    end

    module ClassMethods

      def visible_condition_with_easy_extensions(user, options={})
        Project.allowed_to_condition(user, :view_issues, options) do |role, user|
          if user.logged?
            case role.issues_visibility
            when 'all'
              nil
            when 'default'
              user_ids = [user.id] + user.groups.map(&:id).compact
              "(#{table_name}.is_private = #{connection.quoted_false} OR #{table_name}.author_id = #{user.id} OR #{table_name}.assigned_to_id IN (#{user_ids.join(',')}))"
            when 'own'
              user_ids = [user.id] + user.groups.map(&:id).compact
              "(#{table_name}.author_id = #{user.id} OR #{table_name}.assigned_to_id IN (#{user_ids.join(',')}) OR EXISTS (SELECT w.id FROM #{Watcher.table_name} w WHERE w.watchable_type = 'Issue' AND w.watchable_id = #{Issue.table_name}.id AND w.user_id = #{user.id}))"
            else
              '1=0'
            end
          else
            "(#{table_name}.is_private = #{connection.quoted_false})"
          end
        end
      end

      # cache for current request, event through more than one if they are from same user
      def allowed_target_projects_on_move_with_easy_extensions(user=User.current)
        return @allowed_target_projects_on_move if @allowed_target_projects_on_move && user.id == @allowed_target_projects_on_move_cached_id

        res = allowed_target_projects_on_move_without_easy_extensions(user)
        if user == User.current
          @allowed_target_projects_on_move = res
          @allowed_target_projects_on_move_cached_id = user.id
        end
        res

      end

    end

    module InstanceMethods

      def cache_key_with_easy_extensions
        if new_record?
          'issues/new'
        else
          "issues/#{id}-#{updated_on.strftime('%Y%m%d%H%M%S')}"
        end
      end

      def after_create_from_copy_with_easy_extensions
        return unless copy? && !@after_create_from_copy_handled

        if (@copied_from.project_id == project_id || Setting.cross_project_issue_relations?) && @copy_options[:link] != false
          relation = IssueRelation.new(:issue_from => @copied_from, :issue_to => self, :relation_type => IssueRelation::TYPE_COPIED_TO)
          unless relation.save
            logger.error "Could not create relation while copying ##{@copied_from.id} to ##{id} due to validation errors: #{relation.errors.full_messages.join(', ')}" if logger
          end
        end

        unless @copied_from.leaf? || @copy_options[:subtasks] == false
          copy_options = (@copy_options || {}).merge(:subtasks => false)
          copied_issue_ids = {@copied_from.id => self.id}
          attrs = self.attributes_for_descendants
          @copied_from.reload.descendants.reorder("#{Issue.table_name}.lft").each do |child|
            # Do not copy self when copying an issue as a descendant of the copied issue
            next if child == self
            # Do not copy subtasks of issues that were not copied
            next unless copied_issue_ids[child.parent_id]
            # Do not copy subtasks that are not visible to avoid potential disclosure of private data
            unless child.visible?
              logger.error "Subtask ##{child.id} was not copied during ##{@copied_from.id} copy because it is not visible to the current user" if logger
              next
            end
            copy = Issue.new.copy_from(child, copy_options)
            copy.safe_attributes = attrs.dup if attrs

            custom_field_values = child.custom_field_values.inject({}) {|h,v| h[v.custom_field_id] = v.value; h}
            if attrs
              custom_field_values = custom_field_values.merge(attrs['custom_field_values'] || {})
            end
            copy.custom_field_values = custom_field_values

            copy.mass_operations_in_progress = true
            copy.author = author
            copy.project = project
            copy.parent_issue_id = copied_issue_ids[child.parent_id]
            unless copy.save
              logger.error "Could not copy subtask ##{child.id} while copying ##{@copied_from.id} to ##{id} due to validation errors: #{copy.errors.full_messages.join(', ')}" if logger
              next
            end
            copied_issue_ids[child.id] = copy.id
          end
        end
        @after_create_from_copy_handled = true
      end

      def assignable_users_with_easy_extensions
        users = []
        users.concat(project.assignable_users) if project && !User.current.limit_assignable_users_for_project?(project)
        users << author if author
        users << assigned_to if assigned_to
        users.uniq.sort
      end

      def editable_with_easy_extensions?(user=User.current)
        return @editable if @editable
        @editable = editable_without_easy_extensions? || (user.allowed_to?(:edit_own_issue, self.project) && self.author_id == user.id)
        @editable
      end

      def create_journal_with_easy_extensions
        if @current_journal
          # attributes changes
          if @attributes_before_change
            (Issue.column_names - %w(id root_id lft rgt lock_version created_on updated_on closed_on easy_level easy_external_id easy_repeat_settings easy_next_start)).each {|c|
              before = @attributes_before_change[c]
              after = send(c)
              next if before == after || (before.blank? && after.blank?) || (c == 'description' && Sanitize.clean(before.to_s, :output => :html).strip == Sanitize.clean(after.to_s, :output => :html).strip)
              @current_journal.details << JournalDetail.new(:property => 'attr',
                :prop_key => c,
                :old_value => before,
                :value => after)
            }
          end
          if @custom_values_before_change
            # custom fields changes
            custom_field_values.each do |c|
              next if c.custom_field.field_format == 'easy_rating'
              field_format = Redmine::CustomFieldFormat.find_by_name(c.custom_field.field_format)
              before = @custom_values_before_change[c.custom_field_id]
              after = c.value

              if c.custom_field.field_format == 'amount'
                after = c.custom_field.amount_to_number(after).to_s
                before = c.custom_field.amount_to_number(before).to_s
              end

              next if before == after || (before.blank? && after.blank?)

              if before.is_a?(Array) || after.is_a?(Array)
                before = [before] unless before.is_a?(Array)
                after = [after] unless after.is_a?(Array)

                # values removed
                (before - after).reject(&:blank?).each do |value|
                  @current_journal.details << JournalDetail.new(:property => 'cf',
                    :prop_key => c.custom_field_id,
                    :old_value => value,
                    :value => nil)
                end
                # values added
                (after - before).reject(&:blank?).each do |value|
                  @current_journal.details << JournalDetail.new(:property => 'cf',
                    :prop_key => c.custom_field_id,
                    :old_value => nil,
                    :value => value)
                end
              else
                @current_journal.details << JournalDetail.new(:property => 'cf',
                  :prop_key => c.custom_field_id,
                  :old_value => before,
                  :value => after)
              end
            end
          end
          @current_journal.save
          # reset current journal
          init_journal @current_journal.user, @current_journal.notes
        end
      end

      def safe_attributes_with_easy_extensions=(attrs, user=User.current)
        @should_send_invitation_update = !!attrs.delete(:should_send_invitation_update) if attrs.is_a?(Hash)
        reformat_meeting_datetime_attributes(attrs)
        send :safe_attributes_without_easy_extensions=, attrs, user
        return unless attrs.is_a?(Hash)

        if attrs
          if !attrs['fixed_version_id'].blank? && (current_version = Version.find_by_id(attrs['fixed_version_id'])) # the version is changing

            if !attrs['old_fixed_version_id'].blank?
              previous_version = Version.find_by_id(attrs['old_fixed_version_id'])
            elsif !self.fixed_version_id_was.blank?
              previous_version = Version.find_by_id(self.fixed_version_id_was) if self.fixed_version_id_was
            end

            if attrs.key?('due_date')
              attrs_due_date = begin; attrs['due_date'].to_date; rescue; nil; end
            else
              attrs_due_date = self.due_date
            end

            if previous_version && ((attrs_due_date.blank? && (previous_version != current_version)) || (attrs_due_date == previous_version.due_date))
              attrs_due_date = current_version.due_date
            end

            if previous_version.nil? && attrs_due_date.blank?
              attrs_due_date = current_version.due_date
            end

            attrs['due_date'] = attrs_due_date
          end

          attrs.delete('old_fixed_version_id')
        end

        # User can change issue attributes only if he has :edit permission or if a workflow transition is allowed
        attrs = delete_unsafe_attributes(attrs, user)
        return if attrs.blank?

        assign_attributes attrs, :without_protection => true
      end

      def assignable_groups
        project.assignable_groups if project
      end

      def assignable_users_and_groups
        project.assignable_users_and_groups if project
      end

      def validate_issue_with_easy_extensions
        if self.due_date && self.start_date && (start_date_changed? || due_date_changed?) && self.due_date < self.start_date
          errors.add :due_date, :greater_than_start_date2, :due_date => format_date(self.due_date), :start_date => format_date(self.start_date)
        end

        if self.start_date && start_date_changed? && self.soonest_start && self.start_date < self.soonest_start
          errors.add :start_date, :greater_than_soonest_start, :start_date => format_date(self.start_date), :soonest_start => format_date(self.soonest_start)
        end

        if fixed_version
          if !assignable_versions.include?(fixed_version)
            errors.add :fixed_version_id, :inclusion
          elsif reopened? && fixed_version.closed?
            errors.add :base, I18n.t(:error_can_not_reopen_issue_on_closed_version)
          end
        end

        # Checks that the issue can not be added/moved to a disabled tracker
        if project && (tracker_id_changed? || project_id_changed?)
          unless project.trackers.include?(tracker)
            errors.add :tracker_id, :inclusion
          end
        end

        # Checks parent issue assignment
        if @invalid_parent_issue_id.present?
          errors.add :parent_issue_id, :invalid
        elsif @parent_issue
          if !valid_parent_project?(@parent_issue)
            errors.add :parent_issue_id, :invalid
          elsif (@parent_issue != parent) && (all_dependent_issues.include?(@parent_issue) || @parent_issue.all_dependent_issues.include?(self))
            errors.add :parent_issue_id, :invalid
          elsif !new_record?
            # moving an existing issue
            if @parent_issue.root_id != root_id
              # we can always move to another tree
            elsif move_possible?(@parent_issue)
              # move accepted inside tree
            else
              errors.add :parent_issue_id, :invalid
            end
          end
        end

        if self.fixed_version && self.fixed_version.effective_date && self.due_date
          if self.fixed_version.effective_date < self.due_date && !EasySetting.value('milestone_effective_date_from_issue_due_date')
            errors.add :due_date, :before_milestone, :due_date => format_date(self.due_date), :effective_date => format_date(self.fixed_version.effective_date)
          end
        end

        if !EasySetting.value('project_calculate_due_date') && self.project && !self.project.due_date.blank?
          if self.due_date && self.due_date > self.project.due_date
            errors.add :due_date, :before_project_end, :due_date => format_date(self.due_date), :project_due_date => format_date(self.project.due_date)
          end
        end

        if !EasySetting.value('project_calculate_start_date') && self.project && !self.project.start_date.blank?
          if self.start_date && self.start_date < self.project.start_date
            errors.add :start_date, :after_project_start, :start_date => format_date(self.start_date), :project_start_date => format_date(self.project.start_date)
          end
        end
      end

      def visible_with_easy_extensions?(usr=nil)
        (usr || User.current).allowed_to?(:view_issues, self.project) do |role, user|
          if user.logged?
            case role.issues_visibility
            when 'all'
              true
            when 'default'
              !self.is_private? || self.author == user || user.is_or_belongs_to?(assigned_to)
            when 'own'
              self.author == user || user.is_or_belongs_to?(assigned_to) || self.watcher_users.include?(user)
            else
              false
            end
          else
            !self.is_private?
          end
        end
      end

      def css_classes_with_easy_extensions(user=User.current, lvl=nil)
        css = css_classes_without_easy_extensions(user)
        if lvl && lvl > 0
          css << ' idnt'
          css << " idnt-#{lvl}"
        end
        css << ' multieditable-container'

        scheme = case EasySetting.value('issue_color_scheme_for')
        when 'issue_priority'
          priority.try(:easy_color_scheme)
        when 'issue_status'
          status.try(:easy_color_scheme)
        when 'tracker'
          tracker.try(:easy_color_scheme)
        end
        css << " scheme #{scheme}" if scheme.present?

        return css
      end

      def estimated_hours_with_easy_extensions=(h)
        write_attribute :estimated_hours, (h.is_a?(String) ? (h.to_hours || h) : h)
      end

      def to_s_with_easy_extensions
        if EasySetting.value('show_issue_id', self.project_id)
          to_s_with_id
        else
          to_s_without_id
        end
      end

      def recalculate_attributes_for_with_easy_extensions(issue_id)
        if issue_id && (p = Issue.find_by_id(issue_id, :include => :project)) && EasySetting.value('issue_recalculate_attributes', p.project)
          journal = p.init_journal(User.current, "<p>#{l(:label_issue_automatic_recalculate_attributes, :issue_id => "##{self.id}")}</p>")
          something_changed = false

          # priority = highest priority of children
          if priority_position = p.children.maximum("#{IssuePriority.table_name}.position", :joins => :priority)
            parent_new_priority = IssuePriority.find_by_position(priority_position)
            if parent_new_priority != p.priority
              p.priority = parent_new_priority
              something_changed = true
            end
          end

          # start/due dates = lowest/highest dates of children
          parent_new_start_date = p.children.minimum(:start_date)
          parent_new_due_date = p.children.maximum(:due_date)
          if parent_new_start_date && parent_new_due_date && parent_new_due_date < parent_new_start_date
            parent_new_start_date, parent_new_due_date = parent_new_due_date, parent_new_start_date
          end

          if parent_new_start_date != p.start_date || parent_new_due_date != p.due_date
            p.start_date = parent_new_start_date
            p.due_date = parent_new_due_date
            something_changed = true
          end

          # done ratio = weighted average ratio of leaves
          unless Issue.use_status_for_done_ratio? && p.status && p.status.default_done_ratio
            leaves_count = p.leaves.count
            if leaves_count > 0
              average = p.leaves.average(:estimated_hours).to_f
              if average == 0
                average = 1
              end
              done = p.leaves.sum("COALESCE(CASE WHEN estimated_hours > 0 THEN estimated_hours ELSE NULL END, #{average}) " +
                  "* (CASE WHEN is_closed = #{connection.quoted_true} THEN 100 ELSE COALESCE(done_ratio, 0) END)", :joins => :status).to_f
              progress = done / (average * leaves_count)
              parent_new_done_ratio = progress.round

              if parent_new_done_ratio != p.done_ratio
                p.done_ratio = parent_new_done_ratio
                something_changed = true
              end
            end
          end

          # estimate = sum of leaves estimates
          parent_new_estimated_hours = p.leaves.sum(:estimated_hours).to_f
          parent_new_estimated_hours = nil if parent_new_estimated_hours == 0.0

          if parent_new_estimated_hours != p.estimated_hours
            p.estimated_hours = parent_new_estimated_hours
            something_changed = true
          end

          if something_changed
            # ancestors will be recursively updated
            Redmine::Hook.call_hook(:model_issue_before_automatic_change_from_subtask, {:issue => p, :journal => journal})
            p.mass_operations_in_progress = true
            p.save(:validate => false)
          end
        end
      end

      def reschedule_on_with_easy_extensions!(date)
        return if date.nil? || self.mass_operations_in_progress
        if leaf?
          if start_date.nil? || start_date != date
            if start_date && start_date > date
              # Issue can not be moved earlier than its soonest start date
              date = [soonest_start(true), date].compact.max
            end
            self.init_journal(User.current)
            reschedule_on(date)
            begin
              save
            rescue ActiveRecord::StaleObjectError
              reload
              reschedule_on(date)
              save
            end
          end
        else
          leaves.each do |leaf|
            if leaf.start_date
              # Only move subtask if it starts at the same date as the parent
              # or if it starts before the given date
              if start_date == leaf.start_date || date > leaf.start_date
                leaf.reschedule_on!(date)
              end
            else
              leaf.reschedule_on!(date)
            end
          end

        end
        true
      end

      def overdue_with_easy_extensions?
        if due_date.nil?
          false
        elsif due_date.is_a?(Date)
          overdue_without_easy_extensions?
        else
          (due_date < Time.now) && !status.is_closed?
        end
      end

      # Returns an array of statuses that user is able to apply
      def new_statuses_allowed_to_with_easy_extensions(user=User.current, include_default=false)
        if new_record? && @copied_from
          [IssueStatus.default, @copied_from.status].compact.uniq.sort
        else
          initial_status = nil
          if new_record?
            initial_status = IssueStatus.default
          elsif status_id_was
            initial_status = IssueStatus.find_by_id(status_id_was)
          end
          initial_status ||= status

          initial_assigned_to_id = assigned_to_id_changed? ? assigned_to_id_was : assigned_to_id
          assignee_transitions_allowed = initial_assigned_to_id.present? &&
            (user.id == initial_assigned_to_id || user.group_ids.include?(initial_assigned_to_id))

          if project
            if user.admin?
              user_roles = project.user_roles(user)
              user_roles = project.all_members_roles if user_roles.blank?
            else
              user_roles = user.roles_for_project(project)
            end
          else
            user_roles = []
          end

          statuses = initial_status.find_new_statuses_allowed_to(
            user_roles,
            tracker,
            author == user,
            assignee_transitions_allowed
          )
          statuses << initial_status unless statuses.empty?
          statuses << IssueStatus.default if include_default
          statuses = statuses.compact.uniq.sort
          blocked? ? statuses.reject {|s| s.is_closed?} : statuses
        end
      end

      def notified_users_with_easy_extensions
        n_users = notified_users_without_easy_extensions

        # notify previous assignee
        jd = self.journals.includes(:details).order('created_on DESC').collect{|j| j.details.detect{|d| d.prop_key == 'assigned_to_id'}}.compact
        previous_assignee = User.active.where(:id => jd[0].old_value).first if jd.size > 0 && !jd[0].old_value.blank?

        n_users << previous_assignee if previous_assignee && previous_assignee.active? && !n_users.include?(previous_assignee) && (previous_assignee.mail_notification == 'all' || previous_assignee.mail_notification == 'only_my_events')

        # if issue is closed notify second previous assignee
        if self.status && self.status.is_closed?
          second_previous_assignee = User.active.where(:id => jd[1].old_value).first if jd.size > 1 && !jd[1].old_value.blank?
          n_users << second_previous_assignee if second_previous_assignee && second_previous_assignee.active? && !n_users.include?(second_previous_assignee) && (second_previous_assignee.mail_notification == 'all' || second_previous_assignee.mail_notification == 'only_my_events')
        end

        if self.status && self.status.is_closed?
          n_users.reject!{|u| u.pref[:no_notified_if_issue_closing] == true}
        end

        n_users
      end

      def relations_with_easy_extensions
        @relations ||= IssueRelation::Relations.new(self, (relations_from.includes(:issue_to => :project) + relations_to.includes(:issue_from => :project)).sort)
      end

      # Adds a cache even if user is User.current wich should be same as user.nil?
      def workflow_rule_by_attribute_with_easy_extensions(user=nil)
        return @workflow_rule_by_attribute if @workflow_rule_by_attribute && user == User.current

        res = workflow_rule_by_attribute_without_easy_extensions(user)
        @workflow_rule_by_attribute = res if user == User.current
        res

      end

      def send_notification_with_easy_extensions
        return if (self.author && self.author.pref[:no_notification_ever] == true)
        Mailer.send_mail_issue_add(self) if Setting.notified_events.include?('issue_added')
      end

      def copy_from_with_easy_extensions(arg, options={})
        copy = copy_from_without_easy_extensions(arg, options)

        copy.author = @copied_from.author if options[:copy_author]

        copy
      end

    end

  end
end
EasyExtensions::PatchManager.register_model_patch 'Issue', 'EasyPatch::IssuePatch'
