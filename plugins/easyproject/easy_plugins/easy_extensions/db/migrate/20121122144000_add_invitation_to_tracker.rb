class AddInvitationToTracker < ActiveRecord::Migration
  def self.up
    add_column :trackers, :easy_send_invitation, :boolean, {:null => true}
  end

  def self.down
    remove_column :trackers, :easy_send_invitation
  end
end