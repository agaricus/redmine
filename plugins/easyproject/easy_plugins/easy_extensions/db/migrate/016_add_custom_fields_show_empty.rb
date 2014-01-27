class AddCustomFieldsShowEmpty < ActiveRecord::Migration
  def self.up
    add_column :custom_fields, :show_empty, :boolean,  {:null => false, :default => true}
  end

  def self.down
    remove_column :custom_fields, :show_empty
  end
end
