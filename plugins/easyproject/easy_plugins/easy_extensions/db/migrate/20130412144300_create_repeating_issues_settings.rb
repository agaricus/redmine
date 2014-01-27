class CreateRepeatingIssuesSettings < ActiveRecord::Migration
  def self.up
    EasySetting.create(:name => 'allow_repeating_issues', :value => true)
  end

  def self.down
    EasySetting.where(:name => 'allow_repeating_issues').destroy_all
  end

end