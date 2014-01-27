class ChangeEasySynchronizations < ActiveRecord::Migration

  def self.up
    create_table :easy_external_synchronisations, :force => true do |t|
      t.column :external_type, :string, {:null => false, :limit => 2048}
      t.column :external_id, :string, {:null => false, :limit => 2048}
      t.column :external_source, :string, {:null => true, :limit => 2048}
      t.column :entity_type, :string, {:null => true, :limit => 2048}
      t.column :entity_id, :string, {:null => true}
      t.column :status, :integer, {:null => false}
      t.column :note, :text, {:null => true}
      t.column :synchronized_at, :datetime, {:null => false}
    end
  end

  def self.down
  end
end