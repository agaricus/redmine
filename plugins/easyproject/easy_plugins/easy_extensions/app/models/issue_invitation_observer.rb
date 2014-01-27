class IssueInvitationObserver < ActiveRecord::Observer
  observe :issue

  include Rails.application.routes.url_helpers
  include EasyIcalHelper

  def self.default_url_options
    { :host => Setting.host_name, :protocol => Setting.protocol }
  end

  def after_create(issue)
    create_and_send_invitation(issue) if issue.should_send_invitation_update && issue_fit_to_invitation?(issue)
  end

  def after_update(issue)
    create_and_send_invitation(issue) if issue.should_send_invitation_update && issue_fit_to_invitation?(issue)
  end

  protected

  def create_and_send_invitation(issue)
    invitation = issue_to_ical(issue, :method => 'request')
    send_invitation(issue, invitation)
  end

  def send_invitation(issue, invitation)
    IssueInvitationObserverMailer.invitation(issue, invitation).deliver
  end

  def issue_fit_to_invitation?(issue)
    issue && issue.tracker && issue.tracker.easy_send_invitation?
  end

end
