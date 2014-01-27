class CreateEasyPermissions < ActiveRecord::Migration
  def self.up
    create_table :easy_permissions do |t|
      t.string :entity_type, :name , :null => false
      t.integer :entity_id, :null => false
      t.text :user_list, :null => true
    end
  end

  def self.down
    drop_table :easy_permissions
  end
end