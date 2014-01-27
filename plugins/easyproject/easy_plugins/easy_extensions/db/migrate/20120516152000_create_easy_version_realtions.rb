class CreateEasyVersionRealtions < ActiveRecord::Migration
  def self.up
    create_table :easy_version_relations do |t|
      t.column :version_from_id, :integer, :null => false
      t.column :version_to_id, :integer, :null => false
      t.column :relation_type, :string, :default => "", :null => false
      t.column :delay, :integer
    end
  end

  def self.down
    drop_table :easy_version_relations
  end
end
