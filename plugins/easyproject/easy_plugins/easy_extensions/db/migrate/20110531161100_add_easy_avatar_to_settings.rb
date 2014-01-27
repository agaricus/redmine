class AddEasyAvatarToSettings < ActiveRecord::Migration
  def self.up
    EasySetting.create :name => 'avatar_enabled', :value => '1'
  end

  def self.down
    EasySetting.where(:name => 'avatar_enabled').destroy_all
  end
end
