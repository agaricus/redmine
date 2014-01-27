class AddBuiltinToTasks < ActiveRecord::Migration
  def up
    add_column :easy_rake_tasks, :builtin, :integer, {:null => false, :default => 0}
  end

  def down
    remove_column :easy_rake_tasks, :builtin
  end
end
