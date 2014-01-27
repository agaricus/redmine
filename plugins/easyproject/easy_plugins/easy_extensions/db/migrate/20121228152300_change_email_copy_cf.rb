class ChangeEmailCopyCf < ActiveRecord::Migration
  def self.up
    IssueCustomField.where(:internal_name => 'external_mails').update_all(:show_on_more_form => false)
  end

  def self.down
  end
end