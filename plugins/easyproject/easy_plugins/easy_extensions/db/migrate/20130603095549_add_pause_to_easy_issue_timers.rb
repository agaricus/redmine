class AddPauseToEasyIssueTimers < ActiveRecord::Migration

  def self.up
    add_column :easy_issue_timers, :pause, :decimal, :default => 0
    add_column :easy_issue_timers, :paused_at, :datetime
  end

  def self.down
  end

end
