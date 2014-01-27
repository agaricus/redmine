class ChangeTimelogDescription < ActiveRecord::Migration
  def self.up
    change_column :time_entries, :comments, :text, { :null => true }
  end

  def self.down
  end
end
