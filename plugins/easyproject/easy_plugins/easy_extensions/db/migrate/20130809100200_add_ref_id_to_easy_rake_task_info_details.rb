class AddRefIdToEasyRakeTaskInfoDetails < ActiveRecord::Migration
  def self.up
    add_column :easy_rake_task_info_details, :reference_id, :integer, {:null => true}
    add_column :easy_rake_task_info_details, :reference_type, :string, {:null => true}
  end

  def self.down
    remove_column :easy_rake_task_info_details, :reference_id
    remove_column :easy_rake_task_info_details, :reference_type
  end

end