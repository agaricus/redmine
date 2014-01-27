class AddInternalNameToEnumerations < ActiveRecord::Migration
  def up
    add_column :enumerations, :internal_name, :string, {:null => true, :limit => 255}
  end

  def down
    remove_column :enumerations, :internal_name
  end
end
