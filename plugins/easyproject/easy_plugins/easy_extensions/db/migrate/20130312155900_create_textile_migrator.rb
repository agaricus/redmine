class CreateTextileMigrator < ActiveRecord::Migration
  def up
    return if table_exists?(:easy_textile_migrators)
    
    create_table :easy_textile_migrators do |t|
      t.column :entity_type, :string, {:null => false}
      t.column :entity_id, :integer, {:null => false}
      t.column :entity_column, :string, {:null => false}
      t.column :source_formatting, :string, {:null => false}
      t.column :source_text, :text, {:null => false}
      t.column :target_text, :text, {:null => false}
    end

    add_index :easy_textile_migrators, [:entity_type, :entity_id]
  end

  def down
    drop_table :easy_textile_migrators
  end

end
