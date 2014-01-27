module EasyPatch
  module TimeReportPatch

    def self.included(base)
      base.send(:include, InstanceMethods)

      base.class_eval do

        attr_reader :only_me

        alias_method_chain :load_available_criteria, :easy_extensions

      end
    end

    module InstanceMethods

      def load_available_criteria_with_easy_extensions
        @available_criteria = { 'project' => {:sql => "#{TimeEntry.table_name}.project_id",
                                              :klass => Project,
                                              :label => :label_project},
                                 'status' => {:sql => "#{Issue.table_name}.status_id",
                                              :klass => IssueStatus,
                                              :label => :field_status},
                                 'version' => {:sql => "#{Issue.table_name}.fixed_version_id",
                                              :klass => Version,
                                              :label => :label_version},
                                 'category' => {:sql => "#{Issue.table_name}.category_id",
                                                :klass => IssueCategory,
                                                :label => :field_category},
                                 'user' => {:sql => "#{TimeEntry.table_name}.user_id",
                                             :klass => User,
                                             :label => :label_user},
                                 'tracker' => {:sql => "#{Issue.table_name}.tracker_id",
                                              :klass => Tracker,
                                              :label => :label_tracker},
                                 'activity' => {:sql => "#{TimeEntry.table_name}.activity_id",
                                               :klass => TimeEntryActivity,
                                               :label => :label_activity},
                                 'issue' => {:sql => "#{TimeEntry.table_name}.issue_id",
                                             :klass => Issue,
                                             :label => :label_issue}
                               }

        @available_criteria['parent_project'] = {:sql => "#{Project.table_name}.parent_id", :klass => Project, :label => :field_parent}
        @available_criteria['role'] = {:sql => "#{Role.table_name}.id", :klass => Role, :label => :label_role,
          :joins => "LEFT JOIN #{Member.table_name} ON #{TimeEntry.table_name}.user_id = #{Member.table_name}.user_id AND #{TimeEntry.table_name}.project_id = #{Member.table_name}.project_id
          LEFT JOIN #{MemberRole.table_name} ON #{MemberRole.table_name}.member_id = #{Member.table_name}.id
          LEFT JOIN #{Role.table_name} ON #{Role.table_name}.id = #{MemberRole.table_name}.role_id"
        }

        # Add time entry custom fields
        custom_fields = TimeEntryCustomField.all
        # Add project custom fields
        custom_fields += ProjectCustomField.all
        # Add issue custom fields
        custom_fields += (@project.nil? ? IssueCustomField.for_all : @project.all_issue_custom_fields)
        # Add time entry activity custom fields
        custom_fields += TimeEntryActivityCustomField.all

        # Add list and boolean custom fields as available criteria
        custom_fields.each do |cf|
          next if cf.join_for_order_statement.blank?
          @available_criteria["cf_#{cf.id}"] = {:sql => "#{cf.join_alias}.value",
                                                 :joins => cf.join_for_order_statement,
                                                 :format => cf.field_format,
                                                 :label => cf.name}
        end

        @available_criteria
      end

    end
  end
end
EasyExtensions::PatchManager.register_other_patch 'Redmine::Helpers::TimeReport', 'EasyPatch::TimeReportPatch'
