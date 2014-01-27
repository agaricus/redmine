class ChangeEasyExSynchs < ActiveRecord::Migration
  def self.up
    add_column :easy_external_synchronisations, :direction, :string, {:null => false, :default => 'in'}

    change_column :easy_external_synchronisations, :external_type, :string, {:null => true}
    change_column :easy_external_synchronisations, :external_id, :string, {:null => true}
  end

  def self.down
    remove_column :easy_external_synchronisations, :direction
  end
end