class ChangeCustomFieldsType < ActiveRecord::Migration
  def self.up
    change_column :custom_fields, :type, :string, { :null => false, :limit => 255 }
  end

  def self.down
  end
end
