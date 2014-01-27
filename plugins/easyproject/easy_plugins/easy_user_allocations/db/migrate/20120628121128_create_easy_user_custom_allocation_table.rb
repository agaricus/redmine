class CreateEasyUserCustomAllocationTable < ActiveRecord::Migration
  def self.up
    create_table :easy_user_custom_allocations do |t|
      t.references :user, :null => false
      t.references :issue, :null => false
      t.text :custom_allocations, :null => true
    end
  end

  def self.down
  end
end