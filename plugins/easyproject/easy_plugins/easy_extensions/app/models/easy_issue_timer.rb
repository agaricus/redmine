class EasyIssueTimer < ActiveRecord::Base

  belongs_to :user
  belongs_to :issue

  validates :user_id, :issue_id, :presence => true

  default_scope(order(:start))

  scope :running, lambda { where(:end => nil) }

  def self.active?(project=nil)
    scope = EasySetting.where(:name => 'easy_issue_timer_settings')
    if project
      scope = scope.where(:project_id => project.id)
    else
      scope = scope.where(:project_id => nil)
    end
    easy_setting = scope.first
    easy_setting = EasySetting.where(:name => 'easy_issue_timer_settings', :project_id => nil).first if project && easy_setting.nil?

    return !!(easy_setting && easy_setting.value && easy_setting.value[:active])
  end

  def play!
    if self.paused?
      # then unpause
      self.pause += (Time.now - self.paused_at).seconds.to_f
      self.paused_at = nil
    else
      play_set_issue_from_settings

      begin
        self.issue.save!(:validate => false)
      rescue ActiveRecord::StaleObjectError
        self.issue.reload
        play_set_issue_from_settings
        self.issue.save!(:validate => false)
      end
    end

    return self
  end

  def pause!
    self.update_attribute(:paused_at, DateTime.now) unless self.paused?
  end

  def stop!
    setting = get_settings[:end]

    case setting[:assigned_to]
    when :last_user
      assigned_to = issue.last_user_assigned_to
    when :author
      assigned_to = issue.author
    else
      assigned_to = User.where(:id => setting[:assigned_to]).first if setting[:assigned_to].present?
    end

    self.issue.assigned_to = assigned_to if assigned_to
    self.issue.status_id = setting[:status_id] if setting[:status_id] && IssueStatus.exists?(setting[:status_id])
    self.issue.done_ratio = setting[:done_ratio] if setting[:done_ratio]

    self.end = Time.now

    return self.destroy
  end

  def current_hours
    in_pause = if self.paused?
      self.pause + (Time.now - self.paused_at)
    else
      self.pause
    end

    ((Time.now - self.start) - in_pause.seconds) / 1.hour
  end

  def hours
    hour = (((self.end - self.start) - self.pause.seconds) / 1.hour)
    if r = get_settings[:round] && r && r > 0.0
      hour.roundup(r)
    else
      hour.round(2)
    end
  end

  def paused?
    !self.paused_at.nil?
  end

  private

  def get_settings
    return EasySetting.value('easy_issue_timer_settings', issue.project)
  end

  def play_set_issue_from_settings
    setting = get_settings[:start]

    self.issue.init_journal(User.current)

    self.issue.assigned_to = User.current if setting[:assigned_to_me]
    self.issue.status_id = setting[:status_id] if setting[:status_id] && IssueStatus.exists?(setting[:status_id])
  end

end
