class RenameCustomFieldMapping < ActiveRecord::Migration
  def up
    if table_exists?(:custom_field_mapping)
      rename_table :custom_field_mapping, :custom_field_mappings
    end
  end

  def down
    if table_exists?(:custom_field_mappings)
      rename_table :custom_field_mappings, :custom_field_mapping
    end
  end
end
