class AddInternalNameIndexes < ActiveRecord::Migration
  def up
    add_index :enumerations, [:internal_name], :uniq => true
    add_index :trackers, [:internal_name], :uniq => true
    add_index :custom_fields, [:internal_name], :uniq => true
  end

  def down
  end
end
