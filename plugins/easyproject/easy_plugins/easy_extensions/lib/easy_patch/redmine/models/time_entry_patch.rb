module EasyPatch
  module TimeEntryPatch

    def self.included(base)
      base.extend(ClassMethods)
      base.send(:include, InstanceMethods)

      base.class_eval do
        remove_validation :comments, "validates_length_of"

        if EasyAttendance.table_exists?
          has_one :easy_attendance, :class_name => 'EasyAttendance', :foreign_key => 'time_entry_id', :dependent => :destroy
        end

        before_save :set_time_entry_activity
        before_save :cancel_save

        scope :visible_with_archived, lambda {|*args| {
            :include => :project,
            :conditions => Project.allowed_to_condition(args.shift || User.current, :view_time_entries, :include_archived => true)
          }}

        scope :non_templates, lambda {{:include => :project, :conditions => {"#{Project.table_name}.easy_is_easy_template" => false}}}

        attr_accessor :mass_operations_in_progress

        validates :issue_id, :presence => true, :if => Proc.new{|i| EasySetting.value('required_issue_id_at_time_entry')}
        validate :only_open_issue, :if => Proc.new{|i| i.issue && !EasySetting.value('allow_log_time_to_closed_issue') && i.issue.closed? }

        safe_attributes 'easy_time_entry_range', 'hours_hour', 'hours_minute'

        alias_method_chain :validate_time_entry, :easy_extensions
        alias_method_chain :attributes=, :easy_extensions

        class << self

          def create_bulk_time_entry(entry)
            time_entry = TimeEntry.new
            time_entry.safe_attributes = entry

            if entry[:user_id].nil?
              time_entry.user = User.current
            else
              time_entry.user = User.find(entry[:user_id])
            end

            if BulkTimeEntriesController.allowed_project?(entry[:project_id], entry[:user_id])
              if time_entry.issue && time_entry.issue.project_id != entry[:project_id].to_i
                time_entry.project_id = time_entry.issue.project_id
              else
                time_entry.project_id = entry[:project_id] # project_id is protected from mass assignment
              end
            end

            time_entry.save
            time_entry
          end

        end

        def estimated_hours
          self.issue.estimated_hours if self.issue
        end

        def user_roles
          self.user.roles_for_project(self.project)
        end

        def project_root
          self.project.root
        end

        def set_time_entry_activity
          self.activity = self.issue.activity if self.project && self.project.fixed_activity? && self.issue && self.issue.activity
        end

        def cancel_save
          false if self.project.easy_is_easy_template?
        end

        def css_classes
          css = 'time_entry'
          css << '_' + self.issue.css_classes if self.issue.present?

          return css
        end

        def tracker
          self.issue && self.issue.tracker
        end

        private

        def only_open_issue
          errors.add(:issue_id, I18n.t(:text_validation_error_only_open_issue))
        end

      end
    end

    module InstanceMethods

      def attributes_with_easy_extensions=(values, *args)
        if values && values.is_a?(Hash)
          if values[:easy_time_entry_range]
            easy_range_from = values[:easy_time_entry_range][:from]
            easy_range_to = values[:easy_time_entry_range][:to]

            begin
              date = values[:spent_on].blank? ? Time.local(Date.today.to_s) : Time.local(values[:spent_on])
            rescue
              date = Time.local(Date.today.to_s)
            end
            if !easy_range_from.blank? && !easy_range_to.blank?
              values[:easy_range_from] = range_to_datetime(date, easy_range_from)
              values[:easy_range_to] = range_to_datetime(date, easy_range_to)
              values[:hours] = hours_from_range(values[:easy_range_from], values[:easy_range_to]) if values[:easy_range_to] && values[:easy_range_from] && values[:hours].blank?
            end

            values.delete(:easy_time_entry_range)
          end

          if values[:hours_hour] && values[:hours_minute]
            h = values.delete(:hours_hour).to_i
            m = values.delete(:hours_minute).to_i

            values[:hours] = h + (m / 60.0)
          end

          values[:hours] = '' if values[:hours] && (values[:hours].to_s == '0' || values[:hours].to_s == '0.0')
        end



        send :attributes_without_easy_extensions=, values, *args
      end

      def validate_time_entry_with_easy_extensions
        validate_time_entry_without_easy_extensions

        errors.add :hours, :invalid if hours && hours <= 0

        unless User.current.admin?
          unless (EasySetting.value('spent_on_limit_before_today').blank?)
            errors.add :spent_on, :out_of_range if spent_on < (User.current.today - EasySetting.value('spent_on_limit_before_today').to_i)
          end

          unless (EasySetting.value('spent_on_limit_after_today').blank?)
            errors.add :spent_on, :out_of_range if spent_on > (User.current.today + EasySetting.value('spent_on_limit_after_today').to_i)
          end
        end
      end

      private

      def range_to_datetime(date, range)
        if range.index(':')
          hours_index = range.index(':')-1
          minutes_index = range.index(':')+1
        elsif range.length == 4
          hours_index = 1
          minutes_index = 2
        elsif range.length <= 2
          hours_index = minutes_index = range.length
        end
        date + range[0..hours_index].to_i.hours + range[minutes_index..range.length].to_i.minutes if hours_index && minutes_index
      end

      def hours_from_range(from, to)
        to.strftime('%H:%M').to_hours - from.strftime('%H:%M').to_hours
      end

    end

    module ClassMethods

    end
  end
end
EasyExtensions::PatchManager.register_model_patch 'TimeEntry', 'EasyPatch::TimeEntryPatch'
