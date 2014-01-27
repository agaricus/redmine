class AddEmailEasyRakeTasks < ActiveRecord::Migration
  def self.up
    add_column :easy_rake_tasks, :failure_mail, :string, {:null => true}
  end

  def self.down
    remove_column :easy_rake_tasks, :failure_mail
  end

end