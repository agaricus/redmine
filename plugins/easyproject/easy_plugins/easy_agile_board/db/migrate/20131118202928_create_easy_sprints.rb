class CreateEasySprints < ActiveRecord::Migration
  def change
    create_table :easy_sprints do |t|
      t.string :name
      t.date :start_date
      t.date :due_date
      t.references :project

      t.timestamps
    end
    add_index :easy_sprints, :project_id
  end
end
