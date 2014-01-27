class ChangeTimeToDueDate < ActiveRecord::Migration
  def self.up
    remove_column :issues, :easy_due_date_time
    add_column :issues, :easy_due_date_time, :datetime, {:null => true}
  end

  def self.down
  end
end