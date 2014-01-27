class AddPermissionToRoles < ActiveRecord::Migration
  def self.up
    Role.givable.each do |role|
      role.permissions ||= []
      role.permissions << :manage_my_page unless role.permissions.include?(:manage_my_page)
      role.save!
    end
  end

  def self.down
  end
end
