class ChangeProjectName < ActiveRecord::Migration
  def self.up
    change_column :projects, "name", :string, { :null => false, :limit => 255, :default => "" }
  end

  def self.down
    change_column :projects, "name", :string, { :null => false, :limit => 30, :default => "" }
  end
end
