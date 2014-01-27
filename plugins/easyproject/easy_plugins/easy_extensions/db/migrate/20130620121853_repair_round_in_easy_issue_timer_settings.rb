class RepairRoundInEasyIssueTimerSettings < ActiveRecord::Migration
  def up
    EasySetting.transaction do
      EasySetting.where(:name => 'easy_issue_timer_settings').each do |s|
        val = s.value
        if val[:round] == 0.15
          val[:round] = 0.25
          s.value = val
          s.save!
        end
      end
    end
  end

  def down
  end
end
