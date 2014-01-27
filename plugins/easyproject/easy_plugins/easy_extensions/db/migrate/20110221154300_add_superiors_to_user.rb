class AddSuperiorsToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :parent_id, :integer, :default => nil
    add_column :users, :lft, :integer, :default => nil
    add_column :users, :rgt, :integer, :default => nil
    
    add_index :users, [:lft, :rgt]
  end

  def self.down
  end
end
