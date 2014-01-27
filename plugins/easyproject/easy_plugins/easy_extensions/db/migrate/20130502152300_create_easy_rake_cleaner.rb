class CreateEasyRakeCleaner < ActiveRecord::Migration

  def self.up
    t = EasyRakeTaskHistoryCleaner.new(:active => true, :settings => {}, :period => :daily, :interval => 1, :next_run_at => Time.now.beginning_of_day)
    t.builtin = 1
    t.save!
  end

  def self.down
    EasyRakeTaskHistoryCleaner.destroy_all
  end

end