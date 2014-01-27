class AddSystemFlagToGroups < ActiveRecord::Migration
  def self.up
    add_column :users, :easy_system_flag, :boolean, {:null => false, :default => false}
  end

  def self.down
    remove_column :users, :easy_system_flag
  end
end
