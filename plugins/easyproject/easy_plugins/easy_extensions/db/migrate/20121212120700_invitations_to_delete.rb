class InvitationsToDelete < ActiveRecord::Migration
  def self.up
    IssueCustomField.where(:internal_name => 'invitation_from').update_all(:non_deletable => false)
    IssueCustomField.where(:internal_name => 'invitation_to').update_all(:non_deletable => false)
  end

  def self.down
  end
end