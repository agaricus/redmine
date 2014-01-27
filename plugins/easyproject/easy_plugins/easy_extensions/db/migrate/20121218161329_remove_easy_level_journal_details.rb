class RemoveEasyLevelJournalDetails < ActiveRecord::Migration
  def up
    JournalDetail.where(:property => 'attr', :prop_key => 'easy_level').destroy_all
  end

  def down
  end
end
