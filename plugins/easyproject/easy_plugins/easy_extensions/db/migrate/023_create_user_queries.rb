class CreateUserQueries < ActiveRecord::Migration
  def self.up
    create_table :userqueries do |t|
      t.column "name", :string, :default => "", :null => false
      t.column "filters", :text
      t.column "user_id", :integer, :default => 0, :null => false
      t.column "is_public", :boolean, :default => false, :null => false
      t.column "column_names", :text
      t.column "sort_criteria", :text
      t.column "group_by", :string
    end
  end

  def self.down
    drop_table :userqueries
  end
end
