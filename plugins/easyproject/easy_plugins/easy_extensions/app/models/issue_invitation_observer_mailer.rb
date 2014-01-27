class IssueInvitationObserverMailer < EasyBlockMailer

  def invitation(issue, invitation)
    headers[:content_type] = 'text/calendar; charset=UTF-8; method=REQUEST'

    sbj = "Invitation: #{issue.subject} @ #{Time.now.strftime('%a %b %H:%M')} - #{Time.now.strftime('%H:%M')} (#{issue.author.mail})"
    @invitation = invitation

    mail(:to => issue.recipients, :subject => sbj)
  end

end