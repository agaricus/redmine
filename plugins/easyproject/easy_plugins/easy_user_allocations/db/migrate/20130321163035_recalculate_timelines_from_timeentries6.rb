class RecalculateTimelinesFromTimeentries6 < ActiveRecord::Migration

  def up
    EasyUserAllocation.reallocate!
  end

  def down
  end

end
