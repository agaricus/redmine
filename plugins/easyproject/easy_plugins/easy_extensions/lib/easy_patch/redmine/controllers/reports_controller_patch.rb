module EasyPatch
  module ReportsControllerPatch

    def self.included(base)
      base.send(:include, InstanceMethods)

      base.class_eval do

        before_filter :easy_issue_report_details_custom_fields, :only => [:issue_report_details]

        before_render :issue_report_change_priorities, :only => [:issue_report]
        before_render :issue_report_details_change_priorities, :only => [:issue_report_details]
        before_render :easy_issue_report, :only => [:issue_report]
        before_render :easy_issue_report_details, :only => [:issue_report_details]
        before_render :easy_issue_report_custom_fields, :only => [:issue_report]

        helper :issues
        include IssuesHelper

        def easy_issue_report_custom_fields
          if @project
            @project_issues_cf = (IssueCustomField.where(:is_for_all => true, :field_format => 'list') + @project.issue_custom_fields.where(:field_format => 'list')).uniq
            @left_issues_cf, @right_issues_cf = Issue.by_custom_fields(@project)
          end
        end

        private

        def issue_report_change_priorities
          @priorities = IssuePriority.active
        end

        def issue_report_details_change_priorities
          case params[:detail]
          when "priority"
            @rows = IssuePriority.active
          end
        end

        def easy_issue_report_details_custom_fields
          if params[:detail] =~ /cf_(\d+)$/
            @field = params[:detail]
            cf_id = params[:detail].split('_').last
            cf = IssueCustomField.find(cf_id)
            @rows = cf.possible_values.collect{|v| EasyReportsCfPossibleValue.new(v)}
            @data = Issue.by_custom_field(cf, @project)
            @report_title = cf.name
          end
        end

      end
    end

    module InstanceMethods

      def easy_issue_report
        @assignees = [User.new(:lastname => l(:label_issue_by_unassigned_to))] + (@assignees || [])

        @issues_by_assigned_to = Issue.by_unassigned_to(@project) + @issues_by_assigned_to
      end

      def easy_issue_report_details
        case params[:detail]
        when "assigned_to"
          @field = "assigned_to_id"
          @rows = [User.new(:lastname => l(:label_issue_by_unassigned_to))] + @rows
          @data = Issue.by_unassigned_to(@project) + @data
          @report_title = l(:field_assigned_to)
        end
      end

    end

  end
end
EasyExtensions::PatchManager.register_controller_patch 'ReportsController', 'EasyPatch::ReportsControllerPatch'
