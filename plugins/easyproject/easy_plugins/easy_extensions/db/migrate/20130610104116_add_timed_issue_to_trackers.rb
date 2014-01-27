class AddTimedIssueToTrackers < ActiveRecord::Migration
  def change
    add_column :trackers, :easy_is_meeting, :boolean
  end
end
