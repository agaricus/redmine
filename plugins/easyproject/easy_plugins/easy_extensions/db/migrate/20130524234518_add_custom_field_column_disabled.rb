class AddCustomFieldColumnDisabled < ActiveRecord::Migration
  def up
    add_column :custom_fields, :disabled, :boolean, :default => false, :null => false
  end

  def down
    remove_column :custom_fields, :disabled
  end
end
