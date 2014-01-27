class AddIpToEasyAttendances < ActiveRecord::Migration
  def self.up
    add_column :easy_attendances, :user_ip, :string, {:null => false, :default => ''}
  end

  def self.down
    remove_column :easy_attendances, :user_ip
  end
end
