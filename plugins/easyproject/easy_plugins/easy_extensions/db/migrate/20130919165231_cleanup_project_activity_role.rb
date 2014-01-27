class CleanupProjectActivityRole < ActiveRecord::Migration
  def up
    t = ProjectActivityRole.arel_table;
    ProjectActivityRole.where(t[:activity_id].not_in(TimeEntryActivity.pluck(:id))).delete_all
  end

  def down
  end
end
