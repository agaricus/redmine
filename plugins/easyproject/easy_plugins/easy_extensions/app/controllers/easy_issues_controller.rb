# encoding: UTF-8
require 'utils/file_utils'

class EasyIssuesController < ApplicationController

  menu_item :new_issue, :only => [:new, :create]
  default_search_scope :issues

  before_filter :find_issue, :only => [:description_edit, :description_update, :preview_external_email, :load_repeating, :load_history]
  before_filter :find_optional_project, :only => [:new, :new_for_dialog]
  before_filter :find_project, :only => [:create, :create_from_gantt, :dependent_fields]
  before_filter :build_new_issue_from_params, :only => [:new, :new_for_dialog, :create, :create_from_gantt, :dependent_fields]

  before_filter :authorize, :only => [:description_edit, :description_update, :edit_toggle_description]

  accept_api_auth :create

  helper :journals
  include JournalsHelper
  helper :projects
  include ProjectsHelper
  helper :custom_fields
  include CustomFieldsHelper
  helper :issues
  include IssuesHelper
  helper :issue_relations
  include IssueRelationsHelper
  helper :watchers
  include WatchersHelper
  helper :attachments
  include AttachmentsHelper

  def new
    if @issue.project.nil?
      time_entry = TimeEntry.where(["user_id = ?", User.current.id]).order(:spent_on).select(:project_id).last
      project  = time_entry && time_entry.project
      @issue.project = project if project && project.module_enabled?('issue_tracking')
      @issue.tracker = @issue.project && @issue.project.trackers.first
    end
    render :template => 'issues/new'
  end

  def new_for_dialog
    if @issue.project.nil?
      time_entry = TimeEntry.where(:user_id => User.current.id).order(:spent_on).select(:project_id).last
      @issue.project  = time_entry && time_entry.project
    end
    render :partial => 'new_for_dialog'
  end

  def create
    if @issue.valid?
      ic = IssuesController.new
      ic.params = params
      ic.session = session
      ic.request = request
      ic.response = response
      ic.instance_eval do
        @url = ActionController::UrlRewriter.new(request, {})
      end
      ic.send :find_project
      ic.send :check_for_default_issue_status
      ic.send :build_new_issue_from_params
      ic.send :create

      redirect_to(response["Location"])
    else
      respond_to do |format|
        format.html render( :template => 'issues/new')
        format.js {render(:template => 'issues/create')}
      end
    end
  end

  def dependent_fields
  end

  def render_last_journal
    @issue = Issue.find(params[:id])
    respond_to do |format|
      format.js
    end
  end

  def description_edit
  end

  def description_update
    if params[:issue]
      journal = @issue.init_journal(User.current)
      @issue.description = params[:issue][:description]

      begin
        @issue.save
      rescue ActiveRecord::StaleObjectError
        @issue.reload
        @issue.description = params[:issue][:description]
        @issue.save
      end

      flash[:notice] = l(:notice_successful_update)
    end

    redirect_back_or_default({:controller => 'issues', :action => 'show', :id => @issue})
  end

  def remove_child
    @issue = Issue.find(params[:id])
    @child = Issue.find(params[:child_id])

    @child.parent_issue_id = nil

    respond_to do |format|
      if @child.save
        format.html {redirect_to @issue}
        format.js # remove_child.js.erb
      else
        format.html {
          flash[:error] = @child.errors.full_messages.join(', ')
          redirect_to @issue
        }
        format.js { render :js => "alert('#{@child.errors.full_messages.join(', ')}');" }
      end
    end
  end

  def preview_external_email
    @mail_template = get_easy_mail_template

    if request.put? && !request.xhr?
      new_issue_journal = @issue.init_journal(User.current, l(:text_external_email_sent, :email => @mail_template.mail_recepient))

      uploaded_files = @issue.save_attachments(params[:attachments] || (params[:issue] && params[:issue][:uploads]))

      all_attachments = []
      all_attachments += uploaded_files[:files] unless uploaded_files[:files].blank?
      all_attachments += Attachment.where(:id => params[:ids]).all unless params[:ids].blank?

      email = EasyMailer.easy_issues_external_mail(@mail_template, @issue, @journal, all_attachments)

      tmp_file = EasyUtils::FileUtils.save_email_to_file(email, false)

      if tmp_file
        a = Attachment.new(:file => tmp_file, :author => User.current)
        a.container = @issue
        a.content_type = 'application/octet-stream'
        a.filename = "#{email.subject.to_s}.eml"
        @issue.attachments << a
        tmp_file.close
      end

      @issue.save

      email.deliver

      respond_to do |format|
        format.html { redirect_back_or_default({:controller => 'issues', :action => 'show', :id => @issue}) }
      end
    else
      respond_to do |format|
        format.html
        format.js
      end
    end
  end

  def toggle_description
    @issue = Issue.find(params[:id])
    respond_to do |format|
      format.js
    end
  end

  def load_repeating
    @issue.easy_is_repeating = true
    respond_to do |format|
      format.js
    end
  end

  def load_history
    @journals = @issue.journals.includes(:user, :details).reorder("#{Journal.table_name}.id ASC").all
    @journals.each_with_index {|j,i| j.indice = i+1}
    @journals.reject!(&:private_notes?) unless User.current.allowed_to?(:view_private_notes, @issue.project)
    @journals.reverse! if User.current.wants_comments_in_reverse_order?

    respond_to do |format|
      format.js
    end
  end

  private

  def find_issue
    @issue = Issue.find(params[:id])
    @project = @issue.project if @issue
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_optional_project
    project_id = (params[:issue] && params[:issue][:project_id]) || params[:project_id]
    @project = Project.find(project_id) unless project_id.blank?
  end

  def find_project
    find_optional_project
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def build_new_issue_from_params
    if params[:id].blank?
      @issue = Issue.new
      @issue.copy_from(params[:copy_from]) if params[:copy_from]
      @issue.project = @project
    else
      @issue = @project.issues.visible.find(params[:id]) if @project
    end

    unless @issue
      render_error l(:error_issue_not_found_in_project)
      return false
    end

    if @project
      @issue.project = @project
      # Tracker must be set before custom field values
      tracker_id = (params[:issue] && params[:issue][:tracker_id]) || params[:tracker_id]
      if @project.trackers.exists?(tracker_id)
        @issue.tracker ||= @project.trackers.find(tracker_id)
      else
        @issue.tracker ||= @project.trackers.find(:first)
      end
      if @issue.tracker.nil?
        render_error l(:error_no_tracker_in_project)
        return false
      end
      params[:issue][:tracker_id] = @issue.tracker.id if params[:issue] && @issue.tracker
    end

    @issue.start_date ||= Date.today

    if params[:issue].is_a?(Hash)
      @issue.safe_attributes = params[:issue]
      if User.current.allowed_to?(:add_issue_watchers, @project) && @issue.new_record?
        @issue.watcher_user_ids = params[:issue]['watcher_user_ids']
      end
    end

    @issue.author = User.current
    @priorities = IssuePriority.active
    @allowed_statuses = @issue.new_statuses_allowed_to(User.current, true)
  end

  def get_easy_mail_template
    if request.put? && !request.xhr?
      t = EasyExtensions::EasyMailTemplate.from_params(params)
    else
      t = EasyExtensions::EasyMailTemplate.from_issue(@issue)

      if request.xhr?
        t.mail_cc = params[:mail_cc]
      end

      if @journal = @issue.journals.last
        @issue_url = url_for(:controller => 'issues', :action => 'show', :id => @issue, :anchor => "change-#{@journal.id}")

        t.mail_subject = l(:'mail.subject.issue_edit', :issuestatus => @issue.status.name, :issuesubject => @issue.subject, :projectname => @issue.project.family_name(:separator => ' > '))
        t.mail_body_html = (@journal.notes || '') + '<br />' + render_to_string(:template => 'mailer/issue_edit', :formats => [:html], :layout => false)
        t.mail_body_plain = Sanitize.clean(@journal.notes || '', :output => :html) + "\n" + render_to_string(:template => 'mailer/issue_edit', :formats => [:text], :layout => false)
      else
        @issue_url = @issue_url = url_for(:controller => 'issues', :action => 'show', :id => @issue)

        t.mail_subject = l(:'mail.subject.issue_add', :issuestatus => @issue.status.name, :issuesubject => @issue.subject, :projectname => @issue.project.family_name(:separator => ' > '))
        t.mail_body_html = render_to_string(:template => 'mailer/issue_add', :formats => [:html], :layout => false)
        t.mail_body_plain = render_to_string(:template => 'mailer/issue_add', :formats => [:text], :layout => false)
      end

      if Setting.text_formatting == 'HTML'
        t.mail_body_html ||= ''
        t.mail_body_html << '<blockquote>'
        t.mail_body_html << @issue.description.to_s
        t.mail_body_html << '</blockquote>'
      end
    end
    t
  end

end
