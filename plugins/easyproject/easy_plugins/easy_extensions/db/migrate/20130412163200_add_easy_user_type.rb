class AddEasyUserType < ActiveRecord::Migration
  def self.up
    add_column :users, :easy_user_type, :integer, {:null => false, :default => 1}
  end

  def self.down
    remove_column :users, :easy_user_type
  end

end