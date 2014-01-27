class RemoveIssuesRssReaderFromPageModules < ActiveRecord::Migration
  def self.up
    prev_type = EasyPageModule.inheritance_column

    # Just temporarily
    EasyPageModule.inheritance_column = :_disabled
    EasyPageModule.where(:type => 'EpmIssuesRssReader').destroy_all
    EasyPageModule.inheritance_column = prev_type
  end

  def self.down
  end
end
