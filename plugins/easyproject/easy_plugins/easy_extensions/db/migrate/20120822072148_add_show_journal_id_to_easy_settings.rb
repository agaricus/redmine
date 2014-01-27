class AddShowJournalIdToEasySettings < ActiveRecord::Migration
  def change
    EasySetting.create(:name => 'show_journal_id', :value => false)
  end
end
