class RegisterRakeEasyMoneyProjectCache < ActiveRecord::Migration
  def self.up

    EasyRakeTaskEasyMoneyProjectCache.reset_column_information
    t = EasyRakeTaskEasyMoneyProjectCache.new(:active => true, :settings => {}, :period => :daily, :interval => 1, :next_run_at => Time.local(Date.today.year, Date.today.month, Date.today.day, 23, 0))
    t.builtin = 1
    t.save!

  end

  def self.down
    EasyRakeTaskEasyMoneyProjectCache.destroy_all
  end
end