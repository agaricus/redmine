class AddEasyCacheToSettings < ActiveRecord::Migration
  def self.up
    EasySetting.create :name => 'use_easy_cache', :value => '0'
  end

  def self.down
    EasySetting.where(:name => 'use_easy_cache').destroy_all
  end
end
