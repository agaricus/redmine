class AddClosingToTracker < ActiveRecord::Migration
  def self.up
    add_column :trackers, :easy_do_not_allow_close_if_subtasks_opened, :boolean, {:null => true}
  end

  def self.down
    remove_column :trackers, :easy_do_not_allow_close_if_subtasks_opened
  end
end