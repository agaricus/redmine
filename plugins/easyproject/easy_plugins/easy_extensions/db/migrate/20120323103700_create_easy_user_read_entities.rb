class CreateEasyUserReadEntities < ActiveRecord::Migration
  def self.up

    create_table :easy_user_read_entities  do |t|
      t.column :user_id, :integer, {:null => false}
      t.column :entity_type, :string, {:limit => 255, :null => false}
      t.column :entity_id, :integer, {:null => false}
      t.column :read_on, :datetime, {:null => false}
    end

    add_index :easy_user_read_entities, [:user_id, :entity_type, :entity_id], :unique => true, :name => 'idx_easy_read_user_entities_1'

  end

  def self.down
    drop_table :easy_user_read_entities
  end
end
