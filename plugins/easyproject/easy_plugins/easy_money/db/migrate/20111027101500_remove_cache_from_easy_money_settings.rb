class RemoveCacheFromEasyMoneySettings < ActiveRecord::Migration
  def self.up
    EasyMoneySettings.find(:all, :conditions => { :name => 'cache' }).each{|ems| ems.destroy}
  end

  def self.down
  end
end