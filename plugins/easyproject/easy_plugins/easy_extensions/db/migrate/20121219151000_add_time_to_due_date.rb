class AddTimeToDueDate < ActiveRecord::Migration
  def self.up
    add_column :issues, :easy_due_date_time, :time, {:null => true}
  end

  def self.down
    remove_column :issues, :easy_due_date_time
  end
end