class AddCustomFieldsShowOnList < ActiveRecord::Migration
  def self.up
    add_column :custom_fields, :show_on_list, :boolean,  {:null => false, :default => false}
  end

  def self.down
    remove_column :custom_fields, :show_on_list
  end
end
