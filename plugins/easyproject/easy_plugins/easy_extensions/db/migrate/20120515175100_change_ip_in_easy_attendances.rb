class ChangeIpInEasyAttendances < ActiveRecord::Migration
  def self.up
    rename_column :easy_attendances, :user_ip, :arrival_user_ip
    add_column :easy_attendances, :departure_user_ip, :string, {:null => false, :default => ''}
  end

  def self.down
    rename_column :easy_attendances, :arrival_user_ip, :user_ip
    remove_column :easy_attendances, :departure_user_ip
  end
end
