class CreateRedmineMailHeaderSettings < ActiveRecord::Migration
  def self.up
    EasySetting.create(:name => 'just_one_issue_mail', :value => false)
  end

  def self.down
    EasySetting.where(:name => 'just_one_issue_mail').destroy_all
  end

end