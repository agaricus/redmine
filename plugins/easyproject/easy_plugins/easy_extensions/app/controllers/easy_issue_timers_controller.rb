class EasyIssueTimersController < ApplicationController

  layout 'admin'

  menu_item :easy_issue_timer_settings

  before_filter :load_easy_issue_timer_settings, :authorize_global, :except => [:play, :stop, :pause]
  before_filter :find_issue, :authorize, :only => [:play, :stop, :pause]

  def settings
    @statuses = IssueStatus.order(:position).all
  end

  def update_settings
    @statuses = IssueStatus.order(:position).all
    attrs = params.dup
    attrs.delete_if{|k,v| v.blank?}

    if @project && @easy_setting.project_id.nil?
      @easy_setting = EasySetting.new(:name => :easy_issue_timer_settings, :project_id => @project.id)
    end

    @setting[:active] = attrs[:active].to_boolean

    if @setting[:active]

      @setting[:round] = attrs[:round].to_f if attrs[:round]

      @setting[:start] = {:assigned_to_me => attrs[:assigned_to_me] && attrs[:assigned_to_me].to_boolean}
      @setting[:start][:status_id] = attrs[:start_status_id] && IssueStatus.find(attrs[:start_status_id]).id

      @setting[:end] = {}
      @setting[:end][:assigned_to] = attrs[:assigned_to] && ([:author, :last_user].detect{|o| o == attrs[:assigned_to].to_sym} || User.active.find(attrs[:assigned_to]).id)
      @setting[:end][:status_id] = attrs[:end_status_id] && IssueStatus.find(attrs[:end_status_id]).id
      @setting[:end][:done_ratio] = attrs[:done_ratio] && attrs[:done_ratio].to_i
    end

    @easy_setting.value = @setting

    if @easy_setting.save
      flash[:notice] = l(:notice_successful_update)
    else
      flash[:error] = l(:error_update_easy_issue_timer_settings)
    end

    if @project
      redirect_to(settings_project_path(@project, :tab => 'easy_issue_timer'))
    else
      render :settings
    end
  end

  def play
    render_403 if !EasyIssueTimer.active?(@issue.project)

    @easy_issue_timer = EasyIssueTimer.where(:id => params[:timer_id]).first
    if @easy_issue_timer.nil? && @issue.easy_issue_timers.where(:user_id => User.current.id, :end => nil).any?
      redirect_to @issue
    else
      EasyIssueTimer.transaction do
        @easy_issue_timer ||= @issue.easy_issue_timers.build(:user => User.current, :start => DateTime.now)
        @easy_issue_timer.play!
        @easy_issue_timer.save!

        EasyIssueTimer.where(EasyIssueTimer.arel_table[:id].not_eq(@easy_issue_timer.id)).where(:user_id => User.current.id).each do |t|
          t.pause!
        end
      end

      flash[:notice] = l(:notice_successful_update)

      redirect_to @issue
    end
  end

  def pause
    @easy_issue_timer = EasyIssueTimer.where(:id => params[:timer_id]).first
    if @easy_issue_timer
      @issue = @easy_issue_timer.issue
      @easy_issue_timer.pause!

      redirect_to @issue
    else
      render_404
    end
  end

  def stop
    @easy_issue_timer = EasyIssueTimer.where(:id => params[:timer_id]).first
    if @easy_issue_timer
      @easy_issue_timer = @easy_issue_timer.stop!

      redirect_to(edit_issue_path(@issue, :issue => {:assigned_to_id => @easy_issue_timer.issue.assigned_to_id, :status_id => @easy_issue_timer.issue.status_id, :done_ratio => @easy_issue_timer.issue.done_ratio, }, :time_entry => {
            :hours => @easy_issue_timer.hours, :easy_range_from => @easy_issue_timer.start.to_time, :easy_range_to => @easy_issue_timer.end.to_time
          }))
    else
      redirect_to @issue
    end
  end

  private

  def load_easy_issue_timer_settings
    @project = Project.find(params[:project_id]) if params[:project_id]

    scope = EasySetting.where(:name => 'easy_issue_timer_settings')
    if @project
      scope = scope.where(:project_id => @project.id)
    else
      scope = scope.where(:project_id => nil)
    end

    @easy_setting = scope.first || EasySetting.new(:name => 'easy_issue_timer_settings', :project_id => @project)

    @easy_setting.reload unless @easy_setting.new_record?

    @setting = @easy_setting.value || Hash.new
  end

end
