class EasyMailer < EasyBlockMailer

  def easy_attendance_added(easy_attendance)
    @easy_attendance = easy_attendance
    mail :to => easy_attendance.easy_attendance_activity.mail, :subject => l(:'easy_attendance.mail_added.subject', :user => easy_attendance.user.name)
  end

  def easy_attendance_updated(easy_attendance)
    @easy_attendance = easy_attendance
    mail :to => easy_attendance.easy_attendance_activity.mail, :subject => l(:'easy_attendance.mail_updated.subject', :user => easy_attendance.user.name)
  end

  def easy_issues_external_mail(mail_template, issue, journal = nil, all_attachments = [])
    redmine_headers 'Project' => issue.project.id,
      'Issue-Id' => issue.id,
      'Issue-Author' => issue.author.login
    redmine_headers 'Issue-Assignee' => issue.assigned_to.login if issue.assigned_to
    message_id(journal || issue)
    references issue

    if all_attachments
      all_attachments.each do |att|
        attachments[att.filename] = File.read(att.diskfile, :mode => 'rb')
      end
    end

    @author = (journal && journal.user) || (issue.author) # redmine inner logic in "mail" function
    @mail_template = mail_template

    if issue.respond_to?(:maintained_easy_helpdesk_project) && issue.maintained_easy_helpdesk_project
      @mail_template.email_header = issue.maintained_easy_helpdesk_project.email_header unless issue.maintained_easy_helpdesk_project.email_header.blank?
      @mail_template.email_footer = issue.maintained_easy_helpdesk_project.email_footer unless issue.maintained_easy_helpdesk_project.email_footer.blank?
    end

    mail :to => mail_template.mail_recepient, :cc => mail_template.mail_cc, :subject => mail_template.mail_subject,
      'From' => mail_template.mail_sender, :reply_to => mail_template.mail_sender
  end

  def easy_attendance_user_arrival_notify(model)
    @user = model.user
    @recipient = model.notify_to
    @easy_attendance_user_arrival_notify = model

    mail(:to => @recipient.mail, :subject => l(:text_easy_attendance_user_notify_default_message, :user => @user))
  end

  def easy_rake_task_check_failure_tasks(task, failed_tasks)
    @task = task
    @failed_tasks = failed_tasks

    mail :to => task.recepients, :subject => task.caption
  end

end