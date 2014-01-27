class ReallocateDoneOpenIssues < ActiveRecord::Migration
  def up
  	Issue.open.where(:done_ratio => 100).all.each do |i|
      EasyUserAllocation.allocate_issue!(i)
  	end
  end

  def down
  end
end
