class AddEasyVersionQueryDefaultColumnListToEasySettings < ActiveRecord::Migration
  def self.up
    EasySetting.create(:name => 'easy_version_query_list_default_columns', :value => ['name', 'effective_date', 'description', 'status', 'sharing'])
  end

  def self.down
    EasySetting.where(:name => 'easy_version_query_list_default_columns').destroy_all
  end
end
