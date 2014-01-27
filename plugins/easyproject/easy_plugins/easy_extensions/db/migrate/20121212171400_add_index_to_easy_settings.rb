class AddIndexToEasySettings < ActiveRecord::Migration
  def self.up
    add_index :easy_settings, [:name, :project_id], :unique => true
  end

  def self.down
  end
end