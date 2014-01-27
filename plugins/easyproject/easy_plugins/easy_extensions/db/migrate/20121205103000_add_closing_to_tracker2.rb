class AddClosingToTracker2 < ActiveRecord::Migration
  def self.up
    add_column :trackers, :easy_do_not_allow_close_if_no_attachments, :boolean, {:null => true}
  end

  def self.down
    remove_column :trackers, :easy_do_not_allow_close_if_no_attachments
  end
end