class AddUserAllocationWorkingPlanModule < ActiveRecord::Migration
  def self.up
    EpmUserAllocationWorkingPlan.install_to_page('my-page')
  end

  def self.down
    EpmUserAllocationWorkingPlan.destroy_all
  end
end
