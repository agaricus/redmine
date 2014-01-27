require File.expand_path('../redmine_test_patch', __FILE__)

module EasyExtensions
  module IssueStatusesControllerTestPatch
    extend RedmineTestPatch

    repair_test :test_update_issue_done_ratio_with_issue_done_ratio_set_to_issue_status do
      with_settings :issue_done_ratio => 'issue_status' do
        post :update_issue_done_ratio
        assert_match /Task done ratios updated./, flash[:notice].to_s
        assert_redirected_to '/issue_statuses'
      end
    end

  end
end
