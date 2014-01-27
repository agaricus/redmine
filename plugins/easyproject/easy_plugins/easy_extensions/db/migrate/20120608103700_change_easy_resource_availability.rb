class ChangeEasyResourceAvailability < ActiveRecord::Migration
  def self.up
    remove_column :easy_resource_availabilities, :name
  end

  def self.down
  end
end