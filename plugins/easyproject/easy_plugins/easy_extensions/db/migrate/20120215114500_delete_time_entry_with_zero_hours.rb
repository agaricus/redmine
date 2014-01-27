class DeleteTimeEntryWithZeroHours < ActiveRecord::Migration
  def self.up
    TimeEntry.find(:all, :conditions => {:hours => 0}).each do |time_entry|
      begin
        time_entry.destroy
      rescue
        time_entry.delete
      end
    end
  end

  def self.down
  end
end