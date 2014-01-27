class AddEasyColorSchemeColumnToEnumerations < ActiveRecord::Migration
  def change
    add_column IssuePriority.table_name, :easy_color_scheme, :string, :null => true
    add_column IssueStatus.table_name, :easy_color_scheme, :string, :null => true
    add_column Tracker.table_name, :easy_color_scheme, :string, :null => true
  end
end
