class AddColumnToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :cached_group_names, :string, :null => false, :limit => 255, :default => ''
  end

  def self.down
    remove_column :users, :cached_group_names
  end
end