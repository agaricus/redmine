class AddEasySettingsUserListDefaultColumns < ActiveRecord::Migration
  def self.up
    EasySetting.create :name => 'user_list_default_columns', :value => ["login", "firstname", "lastname"]
  end

  def self.down
    EasySetting.where(:name => 'user_list_default_columns').destroy_all
  end
end
