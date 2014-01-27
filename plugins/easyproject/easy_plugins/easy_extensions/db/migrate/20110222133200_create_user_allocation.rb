class CreateUserAllocation < ActiveRecord::Migration
  def self.up
    create_table :easy_user_allocations, {:id => false} do |t|
      t.column :user_id, :integer, { :null => false }
      t.column :allocation_timeline, :text, { :null => true }
    end

    add_index :easy_user_allocations, :user_id, :unique => true
  end

  def self.down
    drop_table :easy_user_allocations
  end
end
