class DropNewsUsers < ActiveRecord::Migration
  def self.up
    drop_table :news_users
  end

  def self.down
  end
end
