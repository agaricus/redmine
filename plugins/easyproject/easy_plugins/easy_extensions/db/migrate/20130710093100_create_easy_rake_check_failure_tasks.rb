class CreateEasyRakeCheckFailureTasks < ActiveRecord::Migration

  def self.up
    t = EasyRakeTaskCheckFailureTasks.new(:active => false, :settings => {}, :period => :daily, :interval => 1, :next_run_at => Time.now.beginning_of_day)
    t.builtin = 1
    t.save!
  end

  def self.down
    EasyRakeTaskCheckFailureTasks.destroy_all
  end

end