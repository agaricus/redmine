class AddCustomFieldsComputedToken < ActiveRecord::Migration
  def self.up
    add_column :custom_fields, :computed_token, :string,  {:null => true, :limit => 255}
  end

  def self.down
    remove_column :custom_fields, :computed_token
  end
end
