class AddAvatarsCacheToUsers < ActiveRecord::Migration
  def up
    add_column :users, :easy_avatar, :string, {:length => 255, :null => true}
  end

  def down
    remove_column :users, :easy_avatar
  end
end
