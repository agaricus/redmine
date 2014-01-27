class AddEasyQueriesVisibility < ActiveRecord::Migration
  def up
    if column_exists?(EasyQuery.table_name, :is_public) && !column_exists?(EasyQuery.table_name, :visibility)
      add_column :easy_queries, :visibility, :integer, :default => 0
      EasyQuery.where(:is_public => true).update_all(:visibility => 2)
      remove_column :easy_queries, :is_public
    end
  end

  def down
    # add_column :easy_queries, :is_public, :boolean, :default => true, :null => false
    # EasyQuery.where('visibility <> ?', 2).update_all(:is_public => false)
    # remove_column :easy_queries, :visibility
  end
end
