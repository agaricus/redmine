class CreateEasySynchronizations < ActiveRecord::Migration

  def self.up
    create_table :easy_external_synchronisations, :force => true do |t|
      t.column :entity_type, :string, {:null => false, :limit => 255}
      t.column :entity_id, :integer, {:null => false}
      t.column :enternal_id, :string, {:null => true, :limit => 2048}
      t.column :status, :integer, {:null => false}
      t.column :note, :text, {:null => true}
      t.timestamps
    end
  end

  def self.down
    drop_table :easy_external_synchronisations
  end
end