class CreateEasySyncRelations < ActiveRecord::Migration
  def self.up
    create_table :easy_sync_relations do |t|
      t.column :entity_id, :integer, {:null => false}
      t.column :entity_type, :string, {:limit => 255, :null => false}
      t.column :direction, :string, {:limit => 255, :null => false, :default => 'import'}
      t.column :remote_name, :string, {:limit => 255, :null => false}
      t.column :remote_id, :string, {:limit => 255, :null => false}
      t.column :created_on, :timestamp
      t.column :updated_on, :timestamp
    end
    
  end

  def self.down
    drop_table :easy_sync_relations
  end
end