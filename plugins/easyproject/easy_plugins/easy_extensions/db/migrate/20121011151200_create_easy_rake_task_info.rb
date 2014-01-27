class CreateEasyRakeTaskInfo < ActiveRecord::Migration

  def self.up
    create_table :easy_rake_task_infos, :force => true do |t|
      t.column :easy_rake_task_id, :integer, {:null => false}
      t.column :status, :integer, {:null => false}
      t.column :started_at, :datetime, {:null => false}
      t.column :finished_at, :datetime, {:null => true}
      t.column :note, :text, {:null => true}
    end

    create_table :easy_rake_tasks, :force => true do |t|
      t.column :type, :string, {:null => false, :limit => 2048}
      t.column :active, :boolean, {:null => false, :default => true}
      t.column :settings, :text, {:null => true}
      t.column :period, :string, {:null => false, :limit => 255}
      t.column :interval, :integer, {:null => false}
      t.column :next_run_at, :datetime, {:null => false}
    end
  end

  def self.down
    drop_table :easy_rake_tasks
    drop_table :easy_rake_task_infos
  end
end