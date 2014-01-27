class AddInternalNameToTrackers < ActiveRecord::Migration
  def up
    add_column :trackers, :internal_name, :string, {:null => true, :limit => 255}
  end

  def down
    remove_column :trackers, :internal_name
  end
end
