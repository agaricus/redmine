class CreateEasyProjectRealtions < ActiveRecord::Migration
  def self.up
    create_table :easy_project_relations do |t|
      t.column :project_from_id, :integer, :null => false
      t.column :project_to_id, :integer, :null => false
      t.column :relation_type, :string, :default => "", :null => false
      t.column :delay, :integer
    end
  end

  def self.down
    drop_table :easy_project_relations
  end
end
