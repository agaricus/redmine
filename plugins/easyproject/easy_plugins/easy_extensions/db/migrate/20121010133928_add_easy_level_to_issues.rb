class AddEasyLevelToIssues < ActiveRecord::Migration
  def self.up
    add_column :issues, :easy_level, :integer, :null => true
  end

  def self.down
    remove_column :issues, :easy_level
  end
end