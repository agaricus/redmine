class CreateTimeEntryIndexCreatedOn < ActiveRecord::Migration
  def self.up
    TimeEntry.connection.execute("CREATE INDEX idx_time_entries_created_on_desc ON time_entries (created_on DESC)")
  end

  def self.down
    remove_index :time_entries,  :name => 'idx_time_entries_created_on_desc'
  end

end
