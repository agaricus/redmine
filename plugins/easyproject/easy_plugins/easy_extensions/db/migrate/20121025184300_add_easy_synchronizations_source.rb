class AddEasySynchronizationsSource < ActiveRecord::Migration

  def self.up
    add_column :easy_external_synchronisations, :external_source, :string, {:null => true, :limit => 2048}
  end

  def self.down
  end
end