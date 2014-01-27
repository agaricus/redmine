class CreateEasySchedulerTasks < ActiveRecord::Migration
  def self.up
    create_table :easy_scheduler_tasks do |t|
      t.column :name, :string, { :null => false, :limit => 255, :default => '' }
      t.column :status, :integer, { :null => false, :default => 1 }
      t.column :planned_at, :datetime, { :null => true }
      t.column :started_at, :datetime, { :null => true }
      t.column :finished_at, :datetime, { :null => true }
      t.column :page_url_ident, :string, { :null => true, :limit => 2048 }
    end
  end

  def self.down
    drop_table :easy_scheduler_tasks
  end
end
