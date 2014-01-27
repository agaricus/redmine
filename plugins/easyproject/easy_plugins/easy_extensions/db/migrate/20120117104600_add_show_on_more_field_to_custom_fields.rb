class AddShowOnMoreFieldToCustomFields < ActiveRecord::Migration
  def self.up
    add_column :custom_fields, :show_on_more_form, :boolean, {:null => false, :default => true}
  end

  def self.down
    remove_column :custom_fields, :show_on_more_form
  end
end
