class CreateNewsUsers < ActiveRecord::Migration

  def self.up
    create_table :news_users, :id => false do |t|
      t.column :user_id, :integer, { :null => false }
      t.column :news_id, :integer, { :null => false }
    end
  end

  def self.down
  end
end