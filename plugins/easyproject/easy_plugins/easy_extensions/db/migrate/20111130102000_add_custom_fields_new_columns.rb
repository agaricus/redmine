class AddCustomFieldsNewColumns < ActiveRecord::Migration
  def self.up
    add_column :custom_fields, :non_deletable, :boolean, :null => false, :default => false
    add_column :custom_fields, :non_editable, :boolean, :null => false, :default => false
    add_column :custom_fields, :internal_name, :string, :limit => 255, :null => true
  end

  def self.down
    remove_column :custom_fields, :non_deletable
    remove_column :custom_fields, :non_editable
    remove_column :custom_fields, :internal_name
  end
end
