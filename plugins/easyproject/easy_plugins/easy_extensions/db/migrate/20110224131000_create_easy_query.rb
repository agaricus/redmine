class CreateEasyQuery < ActiveRecord::Migration
  def self.up
    create_table :easy_queries, :force => true do |t|
      t.integer :project_id
      t.string  :name,          :default => '',    :null => false
      t.text    :filters
      t.integer :user_id,       :default => 0,     :null => false
      t.integer :visibility,    :default => 0
      t.text    :column_names
      t.text    :sort_criteria
      t.string  :group_by
      t.string  :type
    end
  end

  def self.down
    drop_table :easy_queries
  end
end
