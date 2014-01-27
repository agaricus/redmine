class AddLimitAssignableUsersToRole < ActiveRecord::Migration
  def self.up
    add_column :roles, :limit_assignable_users, :boolean,  {:null => false, :default => false}
  end

  def self.down
    remove_column :roles, :limit_assignable_users
  end
end
