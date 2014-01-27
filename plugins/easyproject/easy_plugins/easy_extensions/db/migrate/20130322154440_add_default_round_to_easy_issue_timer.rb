class AddDefaultRoundToEasyIssueTimer < ActiveRecord::Migration
  def change
    EasySetting.transaction do
      EasySetting.where(:name => 'easy_issue_timer_settings').each do |s|
        val = s.value
        val[:round] = 0.25
        s.value = val
        s.save!
      end
    end
  end
end
