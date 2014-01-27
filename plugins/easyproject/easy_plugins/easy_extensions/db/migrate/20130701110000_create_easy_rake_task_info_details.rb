class CreateEasyRakeTaskInfoDetails < ActiveRecord::Migration

  def self.up
    create_table :easy_rake_task_info_details, :force => true do |t|
      t.column :easy_rake_task_info_id, :integer, {:null => false}
      t.column :type, :string, {:null => false}
      t.column :status, :integer, {:null => false, :default => 0}
      t.column :detail, :text, {:null => true}
      t.column :entity_type, :string, {:null => true}
      t.column :entity_id, :integer, {:null => true}
    end
  end

  def self.down
    drop_table :easy_rake_task_info_details
  end

end
