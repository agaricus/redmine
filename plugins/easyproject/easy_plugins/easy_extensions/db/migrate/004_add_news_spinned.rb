class AddNewsSpinned < ActiveRecord::Migration
  def self.up
    add_column :news, :spinned, :boolean,  {:null => false, :default => false}
  end

  def self.down
    remove_column :news, :spinned
  end
end
