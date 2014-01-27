module EasyPatch
  module ChangesetPatch

    def self.included(base)
      base.send(:include, InstanceMethods)
      base.class_eval do

        html_fragment :comments, :scrub => :strip

        alias_method_chain :find_referenced_issue_by_id, :easy_extensions
        alias_method_chain :fix_issue, :easy_extensions
        alias_method_chain :log_time_activity, :easy_extensions
        alias_method_chain :scan_comment_for_issue_ids, :easy_extensions

        def scan_comment_for_issue_ids_regexp(keywords_regexp)
          /([\s\(\[,-]|^)((#{keywords_regexp})[\s:]?)?([#|\/]\d+(\s+@#{::Changeset::TIMELOG_RE})?([\s,;&]+#\d+(\s+@#{::Changeset::TIMELOG_RE})?)*)(?=[[:punct:]]|\s|<|$)/i
        end

        def scan_result_for_issue_id_and_hours_regexp
          /[#|\/](\d+)(\s+@#{::Changeset::TIMELOG_RE})?/
        end

        def branches
          repository.scm.changeset_branches(scmid)
        end

      end
    end

    module InstanceMethods

      def find_referenced_issue_by_id_with_easy_extensions(id)
        return nil if id.blank?
        issue = Issue.find_by_id(id.to_i, :include => :project)
        if EasySetting.value('commit_cross_project_ref', repository.project)
          # all issues can be referenced/fixed
        elsif issue
          # issue that belong to the repository project, a subproject or a parent project only
          unless issue.project &&
              (project == issue.project || project.is_ancestor_of?(issue.project) ||
                project.is_descendant_of?(issue.project))
            issue = nil
          end
        end
        issue
      end

      def scan_comment_for_issue_ids_with_easy_extensions
        return if comments.blank?
        # keywords used to reference issues
        ref_keywords = EasySetting.value('commit_ref_keywords', repository.project).downcase.split(',').collect(&:strip)
        ref_keywords_any = ref_keywords.delete('*')
        # keywords used to fix issues
        fix_keywords = EasySetting.value('commit_fix_keywords', repository.project).downcase.split(',').collect(&:strip)

        kw_regexp = (ref_keywords + fix_keywords).collect{|kw| Regexp.escape(kw).gsub(/\//, '\\/')}.join('|')

        referenced_issues = []

        comments.scan(scan_comment_for_issue_ids_regexp(kw_regexp)) do |match|
          action, refs = match[2].to_s.downcase, match[3]
          next unless action.present? || ref_keywords_any

          refs.scan(scan_result_for_issue_id_and_hours_regexp).each do |m|
            issue, hours = find_referenced_issue_by_id(m[0].to_i), m[2]
            if issue
              referenced_issues << issue
              # Don't update issues or log time when importing old commits
              unless repository.created_on && committed_on && committed_on < repository.created_on
                fix_issue(issue, action) if fix_keywords.include?(action)
                log_time(issue, hours) if hours && EasySetting.value('commit_logtime_enabled', repository.project)
              end
            end
          end
        end

        referenced_issues.uniq!
        self.issues = referenced_issues unless referenced_issues.empty?
      end

      def fix_issue_with_easy_extensions(issue, action)
        #        status = IssueStatus.find_by_id(EasySetting.value('commit_fix_status_id', repository.project).to_i)
        #        if status.nil?
        #          logger.warn("No status matches commit_fix_status_id setting (#{EasySetting.value('commit_fix_status_id', repository.project)})") if logger
        #          return issue
        #        end

        # the issue may have been updated by the closure of another one (eg. duplicate)
        issue.reload
        # don't change the status is the issue is closed
        return if issue.status && issue.status.is_closed?

        journal = issue.init_journal(user || User.anonymous, ll(Setting.default_language, :text_status_changed_by_changeset, text_tag(issue.project)))
        #issue.status = status
        #        if asgn_id = EasySetting.value('commit_fix_assignee_id', repository.project)
        #          if asgn_id == 'none'
        #            issue.assigned_to = nil
        #          elsif asgn_id != 'no_change'
        #            u = User.find(asgn_id) if User.exists?(asgn_id)
        #            issue.assigned_to = u if u
        #          end
        #        end
        #        unless EasySetting.value('commit_fix_done_ratio', repository.project).blank?
        #          issue.done_ratio = EasySetting.value('commit_fix_done_ratio', repository.project).to_i
        #        end

        rule = Setting.commit_update_keywords_array.detect do |rule|
          rule['keywords'].include?(action) &&
            (rule['if_tracker_id'].blank? || rule['if_tracker_id'] == issue.tracker_id.to_s)
        end
        if rule
          issue.assign_attributes rule.slice(*Issue.attribute_names)
        end

        Redmine::Hook.call_hook(:model_changeset_scan_commit_for_issue_ids_pre_issue_update, { :changeset => self, :issue => issue, :action => action })
        unless issue.save
          logger.warn("Issue ##{issue.id} could not be saved by changeset #{id}: #{issue.errors.full_messages}") if logger
        end
        issue
      end

      def log_time_activity_with_easy_extensions
        if EasySetting.value('commit_logtime_activity_id', repository.project).to_i > 0
          TimeEntryActivity.find_by_id(EasySetting.value('commit_logtime_activity_id', repository.project).to_i)
        end
      end

    end

  end
end
EasyExtensions::PatchManager.register_model_patch 'Changeset', 'EasyPatch::ChangesetPatch'
