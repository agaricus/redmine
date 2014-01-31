class CreateIssueEasySprintRelations < ActiveRecord::Migration
  def change
    create_table :issue_easy_sprint_relations do |t|
      t.references :issue
      t.references :easy_sprint
      t.integer :relation_type

      t.timestamps
    end
    add_index :issue_easy_sprint_relations, :issue_id
    add_index :issue_easy_sprint_relations, :easy_sprint_id
  end
end
