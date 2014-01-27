class AddDefaultFiltersToEasySetting < ActiveRecord::Migration
  def self.up
    
    EasySetting.create(:name => 'easy_issue_query_default_filters', :value => {'status_id'=> {:operator=>'o', :values=>['']}})
    EasySetting.create(:name => 'easy_user_query_default_filters', :value => {'status' => {:operator => '=', :values => [User::STATUS_ACTIVE.to_s]}})
    EasySetting.create(:name => 'easy_version_query_default_filters', :value => {'status' => {:operator => '=', :values => ['open']}})
    
  end

  def self.down
    EasySetting.where(:name => 'easy_issue_query_default_filters').destroy_all
    EasySetting.where(:name => 'easy_user_query_default_filters').destroy_all
    EasySetting.where(:name => 'easy_version_query_default_filters').destroy_all
  end
end
