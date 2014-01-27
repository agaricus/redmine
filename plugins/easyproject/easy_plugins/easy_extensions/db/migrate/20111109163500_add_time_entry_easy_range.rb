class AddTimeEntryEasyRange < ActiveRecord::Migration
  def self.up
    add_column :time_entries, :easy_range_from, :datetime, :null => true
    add_column :time_entries, :easy_range_to, :datetime, :null => true
  end

  def self.down
    remove_column :time_entries, :easy_range_from
    remove_column :time_entries, :easy_range_to
  end
end
