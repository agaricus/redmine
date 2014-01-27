class AddCustomFieldsIsPrimary < ActiveRecord::Migration
  def self.up
    add_column :custom_fields, :is_primary, :boolean,  {:null => false, :default => true}
  end

  def self.down
    remove_column :custom_fields, :is_primary
  end
end
