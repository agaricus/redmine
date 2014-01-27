class ReallocateClosedIssues < ActiveRecord::Migration
  def up
    Issue.all_to_allocate.open(false).all.each do |issue|
      issue.easy_user_allocations.destroy_all
    end
  end

  def down
  end
end
