class RemoveUsersTree < ActiveRecord::Migration
  def self.up
    remove_index :users, :name => 'idx_users_1'

    remove_index :users, :column => [:lft, :rgt]

    remove_column :users, :parent_id
    remove_column :users, :lft
    remove_column :users, :rgt
  end

  def self.down
  end
end
