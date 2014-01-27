class AddSettingsToCustomField < ActiveRecord::Migration
  def self.up
    add_column :custom_fields, :settings, :text, { :null => true }
  end

  def self.down
    remove_column :custom_fields, :settings
  end
end
