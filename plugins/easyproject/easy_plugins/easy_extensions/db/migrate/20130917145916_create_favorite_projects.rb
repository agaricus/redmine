class CreateFavoriteProjects < ActiveRecord::Migration
  def up
    create_table :favorite_projects, :id => false do |t|
      t.references :project
      t.references :user
    end
    add_index :favorite_projects, [:project_id, :user_id]
    add_index :favorite_projects, :user_id
  end

  def down
    drop_table :favorite_projects
  end
end
