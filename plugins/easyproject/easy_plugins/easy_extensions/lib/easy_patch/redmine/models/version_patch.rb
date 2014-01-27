module EasyPatch
  module VersionPatch

    def self.included(base)
      base.extend(ClassMethods)
      base.send(:include, InstanceMethods)

      attr_accessor :css_shared

      base.class_eval do

        has_many :relations_from, :class_name => 'EasyVersionRelation', :foreign_key => 'version_from_id', :dependent => :delete_all
        has_many :relations_to, :class_name => 'EasyVersionRelation', :foreign_key => 'version_to_id', :dependent => :delete_all

        acts_as_easy_journalized :format_detail_reflection_columns => ['easy_version_category_id']

        belongs_to :easy_version_category

        before_validation :create_easy_version_relations
        validate :validate_effective_date
        validates :project_id, :presence => true

        after_save :reschedule_following_versions
        after_save :create_journal

        attr_accessor :css_shared, :relation, :mass_operations_in_progress

        safe_attributes 'relation', 'project_id', 'easy_version_category_id'

        alias_method_chain :estimated_hours, :easy_extensions

        def update_from_gantt_data(data)
          gantt_date = self.class.parse_gantt_date(data['est'])
          if gantt_date
            self.effective_date = gantt_date
          end
        end

        def update_issues_due_dates(xeffective_date_was)
          if xeffective_date_was
            self.fixed_issues.find(:all, :include => [:status], :conditions => ["#{IssueStatus.table_name}.is_closed = ? AND #{Issue.table_name}.due_date IS NOT NULL", false]).each do |i|
              if i.due_date && self.effective_date && xeffective_date_was
                journal = i.init_journal(User.current)
                i.due_date = (i.due_date + (self.effective_date - xeffective_date_was).days)
                i.save
              end
            end
          else
            self.fixed_issues.each do |i|
              journal = i.init_journal(User.current)
              i.due_date = self.effective_date
              i.save
            end
          end
        end

        def self.update_version_from_gantt_data(data)
          v = self.find(data['id'])
          if v
            v.update_from_gantt_data(data)
            if v.save
              nil
            else
              v
            end
          else
            nil
          end
        end

        def self.parse_gantt_date(date_string)
          if date_string.match('\d{4},\d{1,2},\d{1,2}')
            Date.strptime(date_string, '%Y,%m,%d')
          end
        end

        def css_classes
          css = 'version'
          css << " #{self.status}"
          css << " #{self.css_shared}" if self.css_shared

          return css
        end

        def relations
          @relations ||= (relations_from + relations_to).sort
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

        def create_easy_version_relations
          if self.relation && self.relation['version_to_id']
            [self.relation['version_to_id']].flatten.each do |version_id|
              version = Version.where({ :id => version_id }).first

              if self.relation['relation_type'] == 'precedes'
                self.relations_from.build(:relation_type => 'precedes', :delay => self.relation['delay'], :version_to => version, :version_from => self)
              else
                self.relations_to.build(:relation_type => 'precedes', :delay => self.relation['delay'], :version_to => self, :version_from => version)
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
          if effective_date.nil? || effective_date < date
            self.effective_date = date
            save
            reschedule_following_issues(date)
          elsif effective_date > date
            self.effective_date = date
            reschedule_following_issues(date)
            save
          end
        end

        def reschedule_following_issues(date)
          return if self.mass_operations_in_progress
          self.fixed_issues.find(:all, :include => [:status], :conditions => ["#{IssueStatus.table_name}.is_closed = ? AND #{Issue.table_name}.due_date IS NOT NULL", false]).each do |issue|
            journal = issue.init_journal(User.current)
            issue.due_date = date
            issue.save
          end
        end

        def reschedule_following_versions
          return if self.mass_operations_in_progress
          self.relations_from.find(:all, :conditions => {:relation_type => EasyVersionRelation::TYPE_PRECEDES}).each do |rel|
            if rel.delay
              rel.set_version_to_dates
            end
          end
        end

        def validate_effective_date
          if self.project && !self.effective_date.nil? && !self.project.easy_due_date.nil? && self.effective_date > self.project.easy_due_date
            errors.add :effective_date, :before_project_end, :due_date => format_date(self.effective_date), :project_due_date => format_date(self.project.easy_due_date)
          end
        end

      end
    end

    module InstanceMethods

      def estimated_hours_with_easy_extensions
        if EasySetting.value('issue_recalculate_attributes', self.project)
          @estimated_hours ||= fixed_issues.leaves.sum(:estimated_hours).to_f
        else
          @estimated_hours ||= fixed_issues.sum(:estimated_hours).to_f
        end
      end

    end

    module ClassMethods

    end

  end

end
EasyExtensions::PatchManager.register_model_patch 'Version', 'EasyPatch::VersionPatch'
