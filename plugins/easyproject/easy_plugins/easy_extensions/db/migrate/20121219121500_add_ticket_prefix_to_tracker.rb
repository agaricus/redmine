class AddTicketPrefixToTracker < ActiveRecord::Migration
  def self.up
    add_column :trackers, :easy_issue_prefix, :string, {:null => true, :limit => 255}
  end

  def self.down
    remove_column :trackers, :easy_issue_prefix
  end
end