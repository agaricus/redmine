class CreateEasySyncMappings < ActiveRecord::Migration
  def self.up
    create_table :easy_sync_mappings do |t|
      t.column :category, :string, {:limit => 255}
      t.column :local_id, :integer
      t.column :local_name, :string, {:limit => 255}
      t.column :remote_id, :integer
      t.column :remote_name, :string, {:limit => 255}
      t.column :value_type, :string, {:limit => 25}
    end
    
  end

  def self.down
    drop_table :easy_sync_mappings
  end
end