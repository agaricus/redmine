module EasyPatch
  module ProjectPatch

    def self.included(base)
      base.extend(ClassMethods)
      base.send(:include, InstanceMethods)

      base.class_eval do

        const_set(:STATUS_PLANNED, 15)

        belongs_to :author, :class_name => 'User', :foreign_key => 'author_id'
        has_and_belongs_to_many :project_custom_fields,
          :class_name => 'ProjectCustomField',
          :order => "#{CustomField.table_name}.position",
          :join_table => "#{table_name_prefix}custom_fields_projects#{table_name_suffix}",
          :association_foreign_key => 'custom_field_id'
        has_and_belongs_to_many :favorited_by,
          :class_name => 'User',
          :join_table => "#{table_name_prefix}favorite_projects#{table_name_suffix}",
          :uniq => true

        has_many :easy_settings, :class_name => 'EasySetting', :dependent => :destroy
        has_many :easy_queries, :dependent => :destroy
        has_many :project_activity_roles, :include => [:role_activity, :role]
        has_many :roles, :through => :project_activity_roles
        has_many :role_activities, :through => :project_activity_roles
        has_many :relations_from, :class_name => 'EasyProjectRelation', :foreign_key => 'project_from_id', :dependent => :delete_all
        has_many :relations_to, :class_name => 'EasyProjectRelation', :foreign_key => 'project_to_id', :dependent => :delete_all
        has_many :journals, :as => :journalized, :dependent => :destroy
        has_many :issue_categories, :dependent => :delete_all, :order => "#{IssueCategory.table_name}.lft"

        has_and_belongs_to_many :project_time_entry_activities,
          :join_table => 'projects_activities',
          :foreign_key => 'project_id',
          :association_foreign_key => 'activity_id',
          :class_name => 'TimeEntryActivity'

        remove_validation :identifier
        remove_validation :name, 'validates_length_of'

        validates :identifier, :presence => true, :if => Proc.new{|p| EasySetting.value('project_display_identifiers')}
        validates_uniqueness_of :identifier, :if => Proc.new{|p| EasySetting.value('project_display_identifiers')}
        validates_length_of :identifier, :in => 1..Project::IDENTIFIER_MAX_LENGTH, :if => Proc.new{|p| EasySetting.value('project_display_identifiers')}
        validates_format_of :identifier, :with => /\A(?!\d+$)[a-z0-9\-_]*\z/, :if => Proc.new { |p| EasySetting.value('project_display_identifiers') && p.identifier_changed? }
        validates_exclusion_of :identifier, :in => %w( new ), :if => Proc.new{|p| EasySetting.value('project_display_identifiers')}

        html_fragment :description, :scrub => :strip

        searchable_options[:additional_conditions] = "#{Project.table_name}.easy_is_easy_template = #{connection.quoted_false}"
        searchable_options[:columns] << "#{Journal.table_name}.notes"
        searchable_options[:include] = [:journals]

        acts_as_easy_journalized :non_journalized_columns => ['id', 'lft', 'rgt', 'created_on', 'updated_on']

        safe_attributes 'project_custom_field_ids'
        safe_attributes 'easy_due_date'
        safe_attributes 'easy_start_date'
        safe_attributes 'author_id'
        safe_attributes 'relation'
        safe_attributes 'is_planned'
        safe_attributes 'send_all_planned_emails'
        safe_attributes 'inherit_time_entry_activities',
          :if => lambda {|project, user| project.new_record? }

        after_initialize :default_values
        before_validation :create_easy_project_relations
        before_save :set_planned_status
        after_save :guess_identifier
        after_save :reschedule_following_projects
        after_save :notify_planned_issues
        after_save :create_journal
        after_create :add_all_active_time_entry_activities
        after_move :set_easy_level
        after_move :update_members_notifications
        after_destroy :delete_time_entry_activities

        attr_accessor :nofilter, :relation, :mass_operations_in_progress, :send_all_planned_emails, :inherit_time_entry_activities
        attr_writer :is_planned

        scope :templates, lambda { {:conditions => {:easy_is_easy_template => true}, :order => "#{Project.table_name}.lft"} }
        scope :non_templates, lambda { where(:easy_is_easy_template => false).order("#{Project.table_name}.lft") }
        scope :by_permission, lambda {|*args| {:conditions => Project.by_permission_condition(*args)}}
        scope :archived, lambda { { :conditions => "#{Project.table_name}.status = #{Project::STATUS_ARCHIVED}"} }
        scope :active_and_planned, lambda { where(:status => [Project::STATUS_ACTIVE, Project::STATUS_PLANNED]) }

        alias_method_chain :active?, :easy_extensions
        alias_method_chain :after_parent_changed, :easy_extensions
        alias_method_chain :allowed_parents, :easy_extensions
        alias_method_chain :assignable_users, :easy_extensions
        alias_method_chain :completed_percent, :easy_extensions
        alias_method_chain :copy, :easy_extensions
        alias_method_chain :copy_issues, :easy_extensions
        alias_method_chain :copy_issue_categories, :easy_extensions
        alias_method_chain :copy_members, :easy_extensions
        alias_method_chain :copy_versions, :easy_extensions
        alias_method_chain :due_date, :easy_extensions
        alias_method_chain :enabled_module_names=, :easy_extensions
        alias_method_chain :children, :easy_extensions
        alias_method_chain :safe_attributes=,:easy_extensions
        alias_method_chain :set_parent!,:easy_extensions
        alias_method_chain :siblings, :easy_extensions
        alias_method_chain :shared_versions, :easy_extensions
        alias_method_chain :start_date, :easy_extensions
        alias_method_chain :to_param, :easy_extensions
        alias_method_chain :unarchive, :easy_extensions

        alias_method_chain :update_or_create_time_entry_activity, :easy_extensions
        alias_method_chain :create_time_entry_activity_if_needed, :easy_extensions
        alias_method_chain :active_activities, :easy_extensions
        alias_method_chain :all_activities, :easy_extensions
        alias_method_chain :system_activities_and_project_overrides, :easy_extensions

        alias_method_chain :css_classes, :easy_extensions

        class << self

          alias_method_chain :allowed_to_condition, :easy_extensions
          alias_method_chain :copy_from, :easy_extensions

          def delete_easy_page_modules(project_id)
            ['project-overview'].each do |page_name|
              page = EasyPage.find_by_page_name(page_name)
              unless page.nil?
                EasyPageZoneModule.delete_all("easy_pages_id=#{page.id} AND entity_id=#{project_id}")
              end
            end
          end

          def by_permission_condition(*args)
            user, permission, options = nil, nil, nil

            first_arg = args.shift
            if first_arg.is_a?(User)
              user = first_arg
            elsif first_arg.is_a?(Symbol)
              permission = first_arg
            elsif first_arg.is_a?(Hash)
              options = first_arg
            end

            second_arg = args.shift
            if second_arg.is_a?(Symbol)
              permission = second_arg
            elsif second_arg.is_a?(Hash)
              options = second_arg
            end

            third_arg = args.shift
            if third_arg.is_a?(Hash)
              options = third_arg
            end

            user ||= User.current
            permission ||= :view_project
            options ||= {}

            allowed_to_condition(user, permission, options)
          end

          def update_project_entity_dates(entities, properties, date_delta)
            entities ||= []
            properties ||= []
            date_delta ||= 0

            return if date_delta == 0 || entities.blank? || properties.blank?

            entities.each do |entity|
              properties.each do |property|
                if property == 'created_on' || property == 'updated_on'
                  entity.update_column(property, Time.now) unless entity[property].nil?
                else
                  entity.update_column(property, entity[property] + date_delta.to_i.days) unless entity[property].nil?
                end
              end
            end
          end

          def additional_statement_by_role_for_allowed_to_condition(statement_by_role, user, permission, options={})
            # You can override this
          end

        end

        def all_dependent_version(except=[])
          except << self
          dependencies = []
          relations_from.each do |relation|
            if relation.version_to && !except.include?(relation.version_to)
              dependencies << relation.version_to
              dependencies += relation.version_to.all_dependent_version(except)
            end
          end
          dependencies
        end

        def copy_time_entry_activities_from_parent
          if inherit_time_entry_activities && parent
            copy_fixed_activity(parent)
            copy_activity(parent)
          end
        end

        def parent_project
          @parent_project ||= self.parent
        end

        def main_project
          @main_project ||= self.root if self.parent != self.root && self.root != self
        end

        def delete_easy_page_modules
          Project.delete_easy_page_modules(self.id) unless self.new_record?
        end

        def duration
          (start_date && due_date) ? due_date - start_date : 0
        end

        def create_easy_project_relations
          if self.relation && self.relation['project_to_id']
            [self.relation['project_to_id']].flatten.each do |project_id|
              project = Project.where({ :id => project_id }).first

              if self.relation['relation_type'] == 'precedes'
                self.relations_from.build(:relation_type => 'precedes', :delay => self.relation['delay'], :project_to => project, :project_from => self)
              else
                self.relations_to.build(:relation_type => 'precedes', :delay => self.relation['delay'], :project_to => self, :project_from => project)
              end
            end
          end
        end

        def soonest_start
          @soonest_start ||= (
            relations_to.collect{|relation| relation.successor_soonest_start} +
              ancestors.collect(&:soonest_start)
          ).compact.max
        end

        def reschedule_after(date)
          return if date.nil? || self.mass_operations_in_progress
          if leaf?
            if start_date.nil? || start_date != date
              self.start_date, self.due_date = date, date + duration
              save
              reschedule_following_versions(date + duration)
            end
          else
            leaves.each do |leaf|
              leaf.reschedule_after(date)
            end
          end
        end

        def reschedule_following_projects
          return if self.mass_operations_in_progress
          self.relations_from.find(:all, :conditions => {:relation_type => EasyVersionRelation::TYPE_PRECEDES}).each do |rel|
            if rel.delay
              rel.set_project_to_dates
            end
          end
        end

        def reschedule_following_versions(new_effective_date)
          return if self.mass_operations_in_progress
          self.versions.each do |version|
            version.effective_date = new_effective_date
            version.save
          end
        end

        def reschedule_following_issues(new_due_date)
          return if self.mass_operations_in_progress
          self.issues.each do |issue|
            journal = issue.init_journal(User.current) if issue.start_date || issue.due_date
            issue.start_date = (new_due_date - issue.duration) if issue.start_date
            issue.due_date = new_due_date if issue.due_date
            issue.save
          end
        end

        def default_values
          if new_record?
            self.author_id ||= User.current.id
            unless EasySetting.value('project_calculate_start_date')
              self.easy_start_date ||= Date.today
            end
          end
        end

        def assignable_groups
          assignable_users_and_groups.select {|s| s.class.name == 'Group'}.sort_by(&:name)
        end

        def assignable_users_and_groups
          member_principals.select {|m| m.roles.detect {|r| r.assignable?}}.collect(&:principal).sort_by(&:name)
        end

        def sum_of_issues_estimated_hours_scope(only_self = false)
          scope = Issue.scoped
          if Setting.display_subprojects_issues? && !only_self
            scope = scope.includes(:project).where(["#{Project.table_name}.lft >= ? AND #{Project.table_name}.rgt <= ?", self.lft, self.rgt])
          else
            scope = scope.where(["#{Issue.table_name}.project_id = ?", self.id])
          end
          if EasySetting.value('issue_recalculate_attributes', self)
            scope = scope.where("#{Issue.table_name}.parent_id IS NULL")
          end
          scope = scope.where("#{Issue.table_name}.estimated_hours IS NOT NULL")
          scope
        end

        def sum_of_issues_estimated_hours(only_self = false)
          scope = sum_of_issues_estimated_hours_scope(only_self)
          scope.sum(:estimated_hours) || 0.0
        end

        def sum_of_timeentries
          self.time_entries.sum(:hours)
        end

        def remaining_timeentries
          (self.sum_of_issues_estimated_hours || 0.0) - self.sum_of_timeentries
        end

        def all_members_roles
          @all_members_roles ||= Role.joins(:members).where(:members => {:project_id => self.id}).uniq.order(:position)
        end

        def user_roles(user=nil)
          user ||= User.current
          all_members_roles.where(:members => {:user_id => user.id}).all
        end

        def enabled_role_activity?(role_id, activity_id)
          self.project_activity_roles.find(:first, :conditions => {:role_id => role_id, :activity_id => activity_id}) != nil
        end

        def activities_per_role(user = nil, role_id = nil)
          user ||= User.current
          return self.activities if !EasySetting.value('enable_activity_roles') || (user.admin? && self.all_members_roles.count <= 0) || role_id == 'xAll'

          unless role_id
            user_role = user.roles_for_project(self).first
            if user.admin? && user_role == Role.non_member
              user_role = self.all_members_roles.first
            end
            role_id = user_role.id if user_role
          end

          return self.project_activity_roles.where(:role_id => role_id).collect(&:role_activity)
        end

        def reinitialize_values
          self.custom_values.each{|cv| cv.reinitialize_value}
        end

        def reorder_subprojects!
          self.descendants.each do |subproject|
            subproject.set_parent!(subproject.parent_id)
          end
        end

        # Returns true if current project has any childrens
        def has_childrens?
          return false if self.children.nil?

          self.easy_is_easy_template ?  self.children.templates.length > 0 : self.children.non_templates.length > 0
        end

        def css_project_classes(uniq_prefix = nil, options = {})
          uniq_prefix ||= ''
          s = 'project'
          s << ' root' if root?
          s << ' child' if child?
          s << (leaf? ? ' leaf' : ' parent')
          unless active?
            if archived?
              s << ' archived'
            else
              s << ' closed'
            end
          end
          s << " idnt-#{options[:level] || project.level}"
          s << nofilter if nofilter
          s << ' subproject' if project.child?
          s << (' '+ uniq_prefix +'parentproject_' + project.parent_id.to_s) if project.child?
          s
        end

        # CREATES a TEMPLATE from project and subprojects
        def create_project_templates(options={})
          pr_map = {}
          unsaved_template = nil

          Project.transaction do
            self.self_and_descendants.non_templates.active_and_planned.each do |old_project|
              new_project = old_project.create_project_template(options)
              unless new_project.valid?
                unsaved_template = new_project
                raise ActiveRecord::Rollback
              end
              pr_map[old_project.id] = [new_project.id, old_project.parent_id]
            end
          end

          return unsaved_template if unsaved_template

          pr_map.each do |old_id, others|
            if pr_map[others[1]]
              new_project = Project.find(others[0])

              new_parent_id = others[1] && pr_map[others[1]][0]
              new_project.set_parent!(new_parent_id)
            end
          end

          return nil
        end

        # CREATES a TEMPLATE from project
        def create_project_template(options={})
          new_project = Project.copy_from(self)
          new_project.name = self.name
          new_project.easy_is_easy_template = true
          return new_project unless new_project.valid?
          new_project.save!
          new_project.copy(self, options)
          return new_project
        end

        def to_projects!
          prepare_projects = self.self_and_descendants.templates
          prepare_projects.each do |template|
            template.easy_is_easy_template = false
            template.save!
          end
        end

        # CREATES a PROJECT from template and subprojects. Also used during copying project!
        def project_with_subprojects_from_template(parent_project_id, projects_attributes=nil, options={})
          return nil if (!projects_attributes.is_a?(Array) || !projects_attributes.is_a?(Hash)) && projects_attributes.blank?
          subprojects = self.descendants.all.dup

          if projects_attributes.is_a?(Hash)
            projects_attributes = [projects_attributes]
          end

          new_project = self.project_from_template(parent_project_id, projects_attributes.detect{|a| a["id"] == self.id.to_s}, options)

          return new_project if new_project.nil? || !new_project.valid?

          ids = {self.id => new_project.id}
          unsaved, saved = [], [new_project]

          subprojects.each do |subproject|
            parent_id = ids.has_key?(subproject.parent_id)? ids[subproject.parent_id] : 0
            new_subproject = subproject.project_from_template(parent_id, projects_attributes.detect{|a| a["id"] == subproject.id.to_s}, options)

            if new_subproject.nil? || !new_subproject.valid?
              unsaved << new_subproject
            elsif !new_subproject.nil? && new_subproject.valid?
              saved << new_subproject
              ids[subproject.id] = new_subproject.id
            end
          end

          return new_project, saved, unsaved
        end

        # CREATES a PROJECT from template. Also used during copying project!
        def project_from_template(parent_project_id, project_attributes={}, options={})
          return nil unless project_attributes.is_a?(Hash)

          logger.info "Creating project from #{self.id}-#{self.name}." if EasyExtensions.debug_mode && logger
          t = Time.now

          new_project = Project.copy_from(self)

          if new_project.nil?
            logger.info "Creating project failed." if EasyExtensions.debug_mode && logger
            return nil
          end

          logger.info("Setting new project...") if EasyExtensions.debug_mode && logger
          new_project.safe_attributes = project_attributes.stringify_keys
          new_project.author = User.current

          return new_project unless new_project.valid?

          new_project.easy_is_easy_template = false if self.easy_is_easy_template
          temp_easy_start_date, temp_easy_due_date = new_project.easy_start_date, new_project.easy_due_date
          new_project.attributes = {:easy_start_date => nil, :easy_due_date => nil}
          new_project.save!

          logger.info("Setting parent...") if EasyExtensions.debug_mode && logger
          new_project.set_allowed_parent!(parent_project_id)

          logger.info("Copying project entities...") if EasyExtensions.debug_mode && logger
          new_project.copy(self, options)

          if !User.current.admin?
            begin
              role = Role.find(Setting.new_project_user_role_id) unless Setting.new_project_user_role_id.blank?
            rescue
            end
            if role
              m = members.detect{|x| x.user_id == User.current.id}
              m ||= new_project.members.build(:user => User.current)
              r = m.member_roles.detect{|x| x.role_id == role.id}
              r ||= m.member_roles.build(:role => role)
              m.save if m.new_record?
              r.save if r.new_record?
            end
          end

          if temp_easy_start_date || temp_easy_due_date
            new_project.update_attributes({:easy_start_date => temp_easy_start_date, :easy_due_date => temp_easy_due_date})
          end

          logger.info("Project created successfully in #{Time.now - t}s.") if EasyExtensions.debug_mode && logger

          return new_project
        end

        def all_project_custom_fields
          @all_project_custom_fields ||= (ProjectCustomField.for_all + project_custom_fields).uniq.sort
        end

        # Overrides Redmine::Acts::Customizable::InstanceMethods#available_custom_fields
        def available_custom_fields
          self.all_project_custom_fields
        end

        def start_date=(d)
          unless EasySetting.value('project_calculate_start_date')
            self.easy_start_date = d
          end
        end

        def due_date=(d)
          unless EasySetting.value('project_calculate_due_date')
            self.easy_due_date = d
          end
        end

        def fixed_activity?
          if self.module_enabled?(:time_tracking)
            EasySetting.value('project_fixed_activity', self)
          else
            false
          end
        end

        def relations
          @relations ||= (relations_from + relations_to).sort
        end

        def all_dependent_project(except=[])
          except << self
          dependencies = []
          relations_from.each do |relation|
            if relation.project_to && !except.include?(relation.project_to)
              dependencies << relation.project_to
              dependencies += relation.project_to.all_dependent_project(except)
            end
          end
          dependencies
        end

        def sum_time_entries
          @sum_time_entries ||= self.time_entries.sum(:hours)
        end

        def sum_time_entries_between(date_begin, date_end)
          @sum_time_entries_between ||= self.time_entries.where(["#{TimeEntry.table_name}.spent_on BETWEEN ? AND ?", date_begin, date_end]).sum(:hours)
        end

        def sum_estimated_hours
          @sum_estimated_hours ||= self.issues.sum(:estimated_hours)
        end

        def percentage_of_time_spending
          @percentage_of_time_spending ||= ((self.sum_time_entries / self.sum_estimated_hours) * 100) if self.sum_estimated_hours > 0.0
          @percentage_of_time_spending ||= 0.0
          @percentage_of_time_spending.round
        end

        def display_issue_categories?
          return @display_issue_categories if @display_issue_categories
          @display_issue_categories = !self.trackers.detect{|t| !t.disabled_core_fields.include?('category_id')}.nil?
        end

        # Returns allowed parent depends on project
        # => options:
        # =>    :force => :projects or :templates
        def allowed_parents_scope(options={})
          if options[:force] == :projects
            load_projects = true
          elsif options[:force] == :templates
            load_projects = false
          else
            load_projects = !self.easy_is_easy_template?
          end
          scope = Project
          if load_projects
            scope = scope.non_templates.where(Project.allowed_to_condition(User.current, :add_subprojects))
            scope = scope.where(["#{Project.table_name}.lft < ? OR #{Project.table_name}.rgt > ?", self.lft, self.rgt]) unless self.new_record?
          else
            scope = scope.non_templates.where(Project.allowed_to_condition(User.current, :add_subprojects))
            scope = scope.where(["#{Project.table_name}.lft < ? OR #{Project.table_name}.rgt > ?", self.lft, self.rgt]) unless self.new_record?
          end
          scope
        end

        def update_project_entities_dates(day_shift)
          Project.update_project_entity_dates([self], ["created_on", "updated_on", "easy_start_date", "easy_due_date"], day_shift)
          Project.update_project_entity_dates(self.versions.all, ["created_on", "effective_date", "updated_on"], day_shift)
          Project.update_project_entity_dates(self.issues.all, ["created_on", "start_date", "due_date", "updated_on"], day_shift)
        end

        def is_planned
          if @is_planned.nil?
            self.status == Project::STATUS_PLANNED
          else
            @is_planned
          end
        end

        def editable?(user = User.current)
          return @editable if @editable && user == User.current

          result = user.allowed_to?(:edit_project, self) || (user.allowed_to?(:edit_own_projects, nil, :global => true) && self.author == user)
          @editable = result if user == User.current

          result
        end

        def set_planned_status
          if is_planned.to_s.to_boolean
            self.status = Project::STATUS_PLANNED
          elsif self.status == Project::STATUS_PLANNED
            self.status = Project::STATUS_ACTIVE
          end
        end

        def notify_planned_issues
          if self.send_all_planned_emails == '1' && Setting.notified_events.include?('issue_added')
            self.issues.open.each do |issue|
              Mailer.send_mail_issue_add(issue).deliver
            end
          end
        end

        private

        def copy_activity(source_project)
          delete_time_entry_activities
          source_project.project_time_entry_activities.each do |tea|
            self.project_time_entry_activities << tea unless self.project_time_entry_activities.include?(tea)
          end
          copy_project_activity_roles(source_project)
          copy_fixed_activity(source_project)
        end

        def copy_news(source_project)
          news = News.find(:all, :conditions => {:project_id => source_project.id})
          news.each do |n|
            copy = n.dup
            copy.project_id = self.id
            logger.warn("model_project_copy_before_save ERROR ( source_project: #{source_project.id}, news: #{n.id} )") if !copy.save && logger
          end
        end

        def copy_documents(source_project)
          source_project.documents.each do |d|
            doc_copy = d.dup
            doc_copy.project_id = self.id
            logger.warn("model_project_copy_before_save ERROR ( source_project: #{source_project.id}, doc: #{d.id} )") if !doc_copy.save && logger
            d.attachments.each do |at|
              at_copy = at.dup
              at_copy.container_id = doc_copy.id
              logger.warn("model_project_copy_before_save ERROR ( source_project: #{source_project.id}, attachments #{at.id} )") if !at_copy.save && logger
            end
          end
        end

        def copy_project_activity_roles(source_project)
          source_project.project_activity_roles.each do |par|
            unless ProjectActivityRole.where(:activity_id => par.activity_id, :role_id => par.role_id, :project_id => self.id).exists?
              ProjectActivityRole.create(:activity_id => par.activity_id, :role_id => par.role_id, :project_id => self.id)
            end
          end
        end

        def copy_fixed_activity(source_project)
          EasySetting.copy_project_settings('project_fixed_activity', source_project.id, self.id)
        end

        def copy_easy_page_modules(source_project)
          if source_project.nil? || source_project.new_record?
            logger.error('Failed because source project is new record or nil') if logger
            return
          end

          if self.new_record?
            logger.error('Failed because target project is new record or nil') if logger
            return
          end

          EasyPageZoneModule.clone_by_entity_id(source_project.id, self.id)
        end

        def copy_repository(source_project)
          return if source_project.repository.nil?

          EasySetting.copy_project_settings('commit_ref_keywords', source_project.id, self.id)
          EasySetting.copy_project_settings('commit_fix_keywords', source_project.id, self.id)
          EasySetting.copy_project_settings('commit_fix_status_id', source_project.id, self.id)
          EasySetting.copy_project_settings('commit_fix_done_ratio', source_project.id, self.id)
          EasySetting.copy_project_settings('commit_fix_assignee_id', source_project.id, self.id)
          EasySetting.copy_project_settings('commit_logtime_enabled', source_project.id, self.id)
          EasySetting.copy_project_settings('commit_logtime_activity_id', source_project.id, self.id)

          new_repository = source_project.repository.dup
          new_repository.project_id = self.id

          logger.warn("copy_repository ERROR (source_project: #{source_project.id}, repository: #{source_project.repository.id} )") if !new_repository.save && logger
        end

        def copy_easy_queries(source_project)
          source_project.easy_queries.each do |query|
            new_query = query.class.new
            new_query.attributes = query.attributes.dup.except('id', 'project_id', 'sort_criteria')
            new_query.sort_criteria = query.sort_criteria if query.sort_criteria
            new_query.project = self
            new_query.user_id = query.user_id
            self.easy_queries << new_query
          end
        end

        def calculated_start_date
          first_issue = issue_for_date_calculation(:start)
          [
            first_issue.blank? ? nil : first_issue.start_date,
            shared_versions.minimum('effective_date'),
            Issue.fixed_version(shared_versions).minimum('start_date')
          ].flatten.compact.min
        end

        def calculated_due_date
          last_issue = issue_for_date_calculation(:end)
          [
            last_issue.blank? ? nil : last_issue.due_date,
            shared_versions.maximum('effective_date'),
            Issue.fixed_version(shared_versions).maximum('due_date')
          ].flatten.compact.max
        end

        def guess_identifier
          if EasySetting.value('project_display_identifiers') && self.identifier.blank?
            self.identifier = self.id.to_s
            update_column :identifier, self.id.to_s
          elsif self.identifier.blank?
            update_column :identifier, self.id.to_s
          end
        end

        def issue_for_date_calculation(type)
          ids = [self.id]
          date_attribute = type == :start ? 'start_date' : 'due_date'
          scope = Issue.scoped
          if Setting.display_subprojects_issues?
            scope = scope.includes(:project)
            scope = scope.where(["#{Project.table_name}.lft >= ? AND #{Project.table_name}.rgt <= ?", self.lft, self.rgt])
            scope = scope.where(["#{Project.table_name}.easy_is_easy_template = ?", self.project.easy_is_easy_template?])
          end
          scope = scope.where(["#{date_attribute} IS NOT NULL AND project_id IN (?)", ids])
          scope = scope.reorder("#{date_attribute} #{type == :start ? 'asc' : 'desc'}")
          scope.first
        end

        def add_all_active_time_entry_activities
          unless new_record? || easy_is_easy_template? || inherit_time_entry_activities
            self.connection.execute("INSERT INTO #{ProjectActivity.table_name} (project_id, activity_id) SELECT #{self.id}, e.id FROM #{Enumeration.table_name} e WHERE e.type = 'TimeEntryActivity' AND e.active = #{self.connection.quoted_true} AND e.project_id IS NULL AND e.parent_id IS NULL AND NOT EXISTS(SELECT pa.project_id FROM #{ProjectActivity.table_name} pa WHERE pa.project_id = #{self.id} AND pa.activity_id = e.id)")
          end
        end

        def delete_time_entry_activities # and projects_activity_roles
          self.connection.execute("DELETE FROM #{ProjectActivityRole.table_name} WHERE project_id = #{self.id}")
          self.connection.execute("DELETE FROM #{ProjectActivity.table_name} WHERE project_id = #{self.id}")
        end

        def update_members_notifications
          if parent_id
            members.each do |m|
              m.copy_mail_notification_from_parent(parent_id)
            end
          end
        end

      end
    end

    module InstanceMethods

      def after_parent_changed_with_easy_extensions(parent_was)
        after_parent_changed_without_easy_extensions(parent_was)
        copy_time_entry_activities_from_parent
      end

      # Returns allowed parent depends on project
      # => options:
      # =>    :force => :projects or :templates
      def allowed_parents_with_easy_extensions(options={})
        return @allowed_parents if @allowed_parents

        scope = allowed_parents_scope(options)
        @allowed_parents = scope.all

        if User.current.allowed_to?(:add_project, nil, :global => true) || (!new_record? && parent.nil?)
          @allowed_parents << nil
        end

        unless parent.nil? || @allowed_parents.empty? || @allowed_parents.include?(parent)
          @allowed_parents << parent
        end
        @allowed_parents
      end

      def assignable_users_with_easy_extensions
        #assignable = Setting.issue_group_assignment? ? member_principals : members
        assignable = members
        assignable.select {|m| m.roles.detect {|role| role.assignable?}}.collect {|m| m.principal}.sort
      end

      def to_param_with_easy_extensions
        @to_param ||= (identifier.to_s =~ %r{^\d*$} ? id.to_s : identifier.to_s)
      end

      # Overrides "siblings" named scope.
      def siblings_with_easy_extensions
        self.easy_is_easy_template ? siblings_without_easy_extensions.templates : siblings_without_easy_extensions.non_templates
      end

      # Overrides "children" named scope.
      def children_with_easy_extensions
        self.easy_is_easy_template ? children_without_easy_extensions.templates : children_without_easy_extensions.non_templates
      end

      def enabled_module_names_with_easy_extensions=(module_names)
        send :enabled_module_names_without_easy_extensions=, module_names
        Redmine::Hook.call_hook(:model_project_enabled_module_changed, :project => self)
      end

      def completed_percent_with_easy_extensions(options={:include_subprojects => false})
        if options.delete(:include_subprojects)
          total = self_and_descendants.collect(&:completed_percent).sum

          total / self_and_descendants.count
        else
          if issues.count > 0
            total = issues.sum(:done_ratio)

            total / issues.count
          else
            100
          end
        end
      end

      def unarchive_with_easy_extensions
        return false if ancestors.detect {|a| !a.active?}
        descendants.each do |subproject|
          subproject.update_attribute(:status, Project::STATUS_ACTIVE)
        end
        update_attribute :status, Project::STATUS_ACTIVE
      end

      def copy_members_with_easy_extensions(project)
        members_to_copy = []
        members_to_copy += project.memberships.select {|m| m.principal.is_a?(User)}
        members_to_copy += project.memberships.select {|m| !m.principal.is_a?(User)}

        existing_members = self.memberships.pluck(:user_id)

        members_to_copy.each do |member|
          next if existing_members.include?(member.user_id)

          new_member = Member.new
          new_member.attributes = member.attributes.dup.except("id", "project_id", "created_on")
          # only copy non inherited roles
          # inherited roles will be added when copying the group membership
          role_ids = member.member_roles.reject(&:inherited?).collect(&:role_id)
          next if role_ids.empty?
          new_member.role_ids = role_ids
          new_member.project = self
          self.members << new_member
        end
      end

      def copy_versions_with_easy_extensions(project)
        existing_versions = self.versions.pluck(:name)
        project.versions.each do |version|
          next if existing_versions.include?(version.name)

          new_version = Version.new
          new_version.mass_operations_in_progress = true
          new_version.attributes = version.attributes.dup.except("id", "project_id", "created_on", "updated_on")
          self.versions << new_version
        end
      end

      def copy_issues_with_easy_extensions(project, options={})
        options[:copying_action] ||= :copying_project

        # Stores the source issue id as a key and the copied issues as the
        # value.  Used to map the two togeather for issue relations.
        issues_map = {}

        # Get issues sorted by root_id, lft so that parent issues
        # get copied before their children
        project.issues.reorder('root_id, lft').all.each do |issue|
          new_issue = Issue.new
          new_issue.copy_from(issue, :subtasks => false, :link => false)
          new_issue.custom_values = issue.custom_values.collect {|v| cloned_v = v.dup; cloned_v.customized = new_issue; cloned_v}
          new_issue.mass_operations_in_progress = true
          new_issue.done_ratio = 0 if options[:copying_action] == :creating_template
          new_issue.send :project=, self, true

          # Changing project resets the custom field values
          # TODO: handle this in Issue#project=
          new_issue.custom_field_values = issue.custom_field_values.inject({}) {|h,v| h[v.custom_field_id] = v.value; h}

          # Reassign watchers
          new_issue.watchers = issue.watchers.collect {|w| cloned_w = w.dup; cloned_w.watchable = new_issue; cloned_w}
          # Reassign fixed_versions by name, since names are unique per
          # project and the versions for self are not yet saved
          if issue.fixed_version && issue.fixed_version.project == project
            new_issue.fixed_version = self.versions.detect {|v| v.name == issue.fixed_version.name}
          end
          # Reassign the category by name, since names are unique per
          # project and the categories for self are not yet saved
          if issue.category
            new_issue.category = self.issue_categories.detect {|c| c.name == issue.category.name}
          end
          # Parent issue
          if issue.parent_id
            if copied_parent = issues_map[issue.parent_id]
              new_issue.parent_issue_id = copied_parent.id
            end
          end

          new_issue.save(:validate => false)

          if new_issue.new_record?
            logger.warn "Project#copy_issues: issue ##{issue.id} could not be copied: #{new_issue.errors.full_messages}" if logger
          else
            issues_map[issue.id] = new_issue unless new_issue.new_record?
          end
        end

        # Relations after in case issues related each other
        project.issues.each do |issue|
          new_issue = issues_map[issue.id]
          unless new_issue
            # Issue was not copied
            next
          end

          issue.mass_operations_in_progress = true
          new_issue.mass_operations_in_progress = true

          # Relations
          issue.relations_from.each do |source_relation|
            new_issue_relation = IssueRelation.new
            new_issue_relation.attributes = source_relation.attributes.dup.except("id", "issue_from_id", "issue_to_id")
            new_issue_relation.issue_to = issues_map[source_relation.issue_to_id]
            if new_issue_relation.issue_to.nil? && Setting.cross_project_issue_relations?
              new_issue_relation.issue_to = source_relation.issue_to
            end
            new_issue.relations_from << new_issue_relation
          end

          issue.relations_to.each do |source_relation|
            new_issue_relation = IssueRelation.new
            new_issue_relation.attributes = source_relation.attributes.dup.except("id", "issue_from_id", "issue_to_id")
            new_issue_relation.issue_from = issues_map[source_relation.issue_from_id]
            if new_issue_relation.issue_from.nil? && Setting.cross_project_issue_relations?
              new_issue_relation.issue_from = source_relation.issue_from
            end
            new_issue.relations_to << new_issue_relation
          end
        end

        if project.module_enabled?('time_tracking') && options[:copying_action] != :creating_template
          project.time_entries.each do |t|

            te_attributes = t.attributes.dup.except('id', 'project_id', 'issue_id')
            te_copy = TimeEntry.new(te_attributes)
            te_copy.user_id = t.user_id
            te_copy.mass_operations_in_progress = true
            te_copy.project_id = self.id

            unless t.issue_id.nil?
              new_issue = issues_map[t.issue_id]
              unless new_issue
                logger.warn("model_project_copy_before_save ERROR cannot find new issue ( source_project: #{project.id}, time_entry #{t.id}, issue_id #{t.issue_id} )") if logger
                next
              end
              te_copy.issue_id = new_issue.id
            end

            te_copy.save(:validate => false)
            logger.warn("model_project_copy_before_save ERROR ( source_project: #{project.id}, time_entry #{t.id} )") if te_copy.new_record? && logger
          end
        end
      end

      def copy_issue_categories_with_easy_extensions(project)
        project.issue_categories.each do |issue_category|
          new_issue_category = IssueCategory.new
          new_issue_category.attributes = issue_category.attributes.dup.except('id', 'project_id', 'parent_id', 'lft', 'rgt')
          self.issue_categories << new_issue_category
        end
      end

      # Sets the parent of the project
      # Argument can be either a Project, a String, a Fixnum or nil
      def set_parent_with_easy_extensions!(p)
        unless p.nil? || p.is_a?(Project)
          if p.to_s.blank?
            p = nil
          else
            p = Project.find_by_id(p)
            return false unless p
          end
        end
        #        if p == parent && !p.nil?
        # Nothing to do
        #          true
        #        elsif p.nil? || (p.active? && move_possible?(p))
        if p.nil? || move_possible?(p)
          set_or_update_position_under(p)
          Issue.update_versions_from_hierarchy_change(self)
          true
        else
          # Can not move to the given target
          false
        end
      end

      def set_easy_level(level=self.level)
        return unless self.class.columns.detect{|c| c.name == 'easy_level'}
        update_column(:easy_level, level)
        Project.where(:parent_id => id).each{|p| p.set_easy_level(level + 1)}
      end

      def shared_versions_with_easy_extensions
        if new_record?
          Version.
            includes(:project).
            where("#{Project.table_name}.status <> ? AND #{Version.table_name}.sharing = 'system'", STATUS_ARCHIVED)
        else
          @shared_versions ||= begin
            r = root? ? self : root
            Version.
              includes(:project).
              where("#{Project.table_name}.id = #{id}" +
                " OR (#{Project.table_name}.status <> #{Project::STATUS_ARCHIVED} AND #{Project.table_name}.easy_is_easy_template = #{self.easy_is_easy_template ? self.connection.quoted_true : self.connection.quoted_false} AND (" +
                " #{Version.table_name}.sharing = 'system'" +
                " OR (#{Project.table_name}.lft >= #{r.lft} AND #{Project.table_name}.rgt <= #{r.rgt} AND #{Version.table_name}.sharing = 'tree')" +
                " OR (#{Project.table_name}.lft < #{lft} AND #{Project.table_name}.rgt > #{rgt} AND #{Version.table_name}.sharing IN ('hierarchy', 'descendants'))" +
                " OR (#{Project.table_name}.lft > #{lft} AND #{Project.table_name}.rgt < #{rgt} AND #{Version.table_name}.sharing = 'hierarchy')" +
                "))")
          end
        end
      end

      def start_date_with_easy_extensions
        if EasySetting.value('project_calculate_start_date')
          @start_date ||= calculated_start_date
        else
          @start_date ||= self.easy_start_date
        end
        @start_date
      end

      def due_date_with_easy_extensions
        if EasySetting.value('project_calculate_due_date')
          @due_date ||= calculated_due_date
        else
          @due_date ||= self.easy_due_date
        end
        @due_date
      end

      # options:
      # => :copying_action => :creating_template - delete issue history, time entries, etc.
      # => :copying_action => :creating_project - preserve all entities as possible
      # => :copying_action => :copying_project - preserve all entities as possible as specified at :only parameter.
      def copy_with_easy_extensions(project, options={})
        project = project.is_a?(Project) ? project : Project.find(project)

        to_be_copied = %w(wiki versions issue_categories issues members easy_queries boards documents activity news easy_page_modules)

        Redmine::Hook.call_hook(:model_project_copy_additionals, :source_project => project, :to_be_copied => to_be_copied, :options => options)

        to_be_copied = to_be_copied & options[:only].to_a unless options[:only].nil?

        Project.transaction do
          if save
            reload
            to_be_copied.each do |name|
              t = Time.now
              logger.info("BEGIN Project (#{project.name}).copy #{name}") if EasyExtensions.debug_mode

              copy_method = "copy_#{name}".to_sym
              if method(copy_method).arity == -2
                send copy_method, project, options
              else
                send copy_method, project
              end

              logger.info("END Project (#{project.name}).copy #{name} - duration #{Time.now - t}s") if EasyExtensions.debug_mode
            end
            Redmine::Hook.call_hook(:model_project_copy_before_save, :source_project => project, :destination_project => self, :options => options)
            saved = save
            Redmine::Hook.call_hook(:model_project_copy_after_save, :source_project => project, :destination_project => self, :options => options) if saved
          end
        end
      end

      def update_or_create_time_entry_activity_with_easy_extensions(id, activity_hash)
        # nothing to do
      end

      def create_time_entry_activity_if_needed_with_easy_extensions(activity)
        # nothing to do
      end

      def active_activities_with_easy_extensions(fallback=false)
        if fallback
          active_activities_without_easy_extensions
        else
          self.project_time_entry_activities
        end
      end

      # Returns all the Systemwide and project specific activities
      # (inactive and active)
      def all_activities_with_easy_extensions
        TimeEntryActivity.shared
      end

      def system_activities_and_project_overrides_with_easy_extensions(include_inactive=false)
        # nothing to do
      end

      def active_with_easy_extensions?
        self.status == Project::STATUS_ACTIVE || self.status == Project::STATUS_PLANNED
      end

      def safe_attributes_with_easy_extensions=(attrs, user=User.current)
        return unless attrs.is_a?(Hash)

        if attrs['custom_fields'] && attrs['custom_fields'].is_a?(Array) && !attrs['project_custom_field_ids']
          cf_array = attrs['custom_fields']
        elsif attrs['custom_field_values'] && attrs['custom_field_values'].is_a?(Array) && !attrs['project_custom_field_ids']
          cf_array = attrs['custom_field_values']
        end

        if self.new_record?
          unless cf_array.blank?
            attrs['project_custom_field_ids'] ||= []
            cf_array.each do |cf|
              cf_id = nil

              if !cf['id'].blank?
                cf_id = cf['id'].to_i
              elsif !cf['internal_name'].blank?
                cf_id = CustomField.where(:internal_name => cf['internal_name']).pluck(:id).first
              end

              attrs['project_custom_field_ids'] << cf_id if !cf_id.blank? && !attrs['project_custom_field_ids'].include?(cf_id)
            end
          else
            if attrs['project_custom_field_ids'].blank?
              attrs['project_custom_field_ids'] = self.project_custom_field_ids
            end
          end

          unless attrs['project_custom_field_ids'].blank?
            self.project_custom_field_ids = attrs.delete('project_custom_field_ids')
          end
        end

        send(:safe_attributes_without_easy_extensions=, attrs, user)
      end

      def css_classes_with_easy_extensions(level=nil)
        self.css_project_classes(nil, {:level => level})
      end
    end

    module ClassMethods

      def copy_from_with_easy_extensions(project)
        project = project.is_a?(Project) ? project : Project.find(project)
        # clear unique attributes
        attributes = project.attributes.dup.except('id', 'name', 'identifier', 'status', 'parent_id', 'lft', 'rgt', 'easy_is_easy_template')
        copy = Project.new(attributes)
        copy.mass_operations_in_progress = true
        copy.enabled_modules.clear if copy.enabled_modules
        project.enabled_modules.each{|em| copy.enabled_modules << EnabledModule.new(:name => em.name) }
        copy.trackers = project.trackers
        copy.custom_values = project.custom_values.collect{|v| cloned_v = v.dup; cloned_v.customized = copy; cloned_v}
        copy.project_custom_fields = project.project_custom_fields
        copy.issue_custom_fields = project.issue_custom_fields
        copy
      end

      def allowed_to_condition_with_easy_extensions(user, permission, options={})
        perm = Redmine::AccessControl.permission(permission)
        options ||= {}

        if options[:include_archived]
          base_statement = '1=1'
        else
          base_statement = (perm && perm.read? ? "#{Project.table_name}.status <> #{Project::STATUS_ARCHIVED}" : "#{Project.table_name}.status IN (#{Project::STATUS_ACTIVE},#{Project::STATUS_PLANNED})")
        end

        if perm && perm.project_module
          # If the permission belongs to a project module, make sure the module is enabled
          base_statement << " AND #{Project.table_name}.id IN (SELECT em.project_id FROM #{EnabledModule.table_name} em WHERE em.name='#{perm.project_module}')"
        end

        if options[:project]
          project_statement = "#{Project.table_name}.id = #{options[:project].id}"
          project_statement << " OR (#{Project.table_name}.lft > #{options[:project].lft} AND #{Project.table_name}.rgt < #{options[:project].rgt})" if options[:with_subprojects]
          base_statement = "(#{project_statement}) AND (#{base_statement})"
        end

        if user.admin? || (perm && perm.acts_as_admin?(user))
          base_statement
        else
          statement_by_role = {}
          unless options[:member]
            role = user.builtin_role
            if role.allowed_to?(permission)
              statement_by_role[role] = "#{Project.table_name}.is_public = #{connection.quoted_true}"
            end
          end
          if user.logged?
            Role.where("#{Member.table_name}.user_id = #{user.id}").includes(:members).each do |role|
              if role.allowed_to?(permission)
                statement_by_role[role] = "EXISTS (SELECT m.id FROM #{Member.table_name} m INNER JOIN #{MemberRole.table_name} mr ON mr.member_id = m.id WHERE mr.role_id = #{role.id} AND m.user_id = #{user.id} AND m.project_id = projects.id)"
              end
            end
            additional_statement_by_role_for_allowed_to_condition(statement_by_role, user, permission, options)
          end
          if statement_by_role.empty?
            "1=0"
          else
            if block_given?
              statement_by_role.each do |role, statement|
                if s = yield(role, user)
                  statement_by_role[role] = "(#{statement} AND (#{s}))"
                end
              end
            end
            "((#{base_statement}) AND (#{statement_by_role.values.join(' OR ')}))"
          end
        end
      end

    end

  end

end
EasyExtensions::PatchManager.register_model_patch 'Project', 'EasyPatch::ProjectPatch'
