class AddUserLimit < ActiveRecord::Migration
  def self.up
    EasySetting.create :name => "user_limit", :value => 0
  end

  def self.down
    EasySetting.where(:name => 'user_limit').destroy_all
  end
end
