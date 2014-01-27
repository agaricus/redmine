class ChangeJournalDetailsValues < ActiveRecord::Migration
  def self.up
    change_column :journal_details, :old_value, :text, { :null => true }
    change_column :journal_details, :value, :text, { :null => true }
  end

  def self.down
  end
end
