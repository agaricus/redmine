class AddUserAllocationModule < ActiveRecord::Migration
  def self.up
    EpmUserAllocation.install_to_page('my-page')
  end

  def self.down
    EpmUserAllocation.destroy_all
  end
end
