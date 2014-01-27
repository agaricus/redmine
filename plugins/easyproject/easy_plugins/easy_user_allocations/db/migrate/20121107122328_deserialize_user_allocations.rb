class DeserializeUserAllocations < ActiveRecord::Migration
  def self.up
    drop_table :easy_user_allocations
    drop_table :easy_user_custom_allocations

    create_table :easy_user_allocations do |t|
      t.references :user, :null => false
      t.references :issue, :null => false
      t.date :date, :null => false
      t.float :hours, :null => false, :default => 0
      t.boolean :custom, :null => false, :default => false
    end
  end

  def self.down
  end
end