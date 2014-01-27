class AddEasyQuerySettingsToEasySettings < ActiveRecord::Migration
  def self.up
    
    if issue_sort_a = EasySetting.find(:first, :conditions => {:name => 'issue_default_sorting_array'})
      EasySetting.create(:name => 'easy_issue_query_default_sorting_array', :value => issue_sort_a.value)
    end
    if issue_sort_s = EasySetting.find(:first, :conditions => {:name => 'issue_default_sorting_string_short'})
      EasySetting.create(:name => 'easy_issue_query_default_sorting_string_short', :value => issue_sort_s.value)
    end
    if issue_sort_l = EasySetting.find(:first, :conditions => {:name => 'issue_default_sorting_string_long'})
      EasySetting.create(:name => 'easy_issue_query_default_sorting_string_long', :value => issue_sort_l.value)
    end
    if issue_columns = Setting['issue_list_default_columns']
      EasySetting.create(:name => 'easy_issue_query_list_default_columns', :value => issue_columns)
    end
    if user_columns = EasySetting.find(:first, :conditions => {:name => 'user_list_default_columns'})
      EasySetting.create(:name => 'easy_user_query_list_default_columns', :value => user_columns.value)
    end
    if project_columns = EasySetting.find(:first, :conditions => {:name => 'project_list_default_columns'})
      EasySetting.create(:name => 'easy_project_query_list_default_columns', :value => project_columns.value)
    end
    
  end

  def self.down
    EasySetting.where(:name => 'easy_issue_query_default_sorting_array').destroy_all
    EasySetting.where(:name => 'easy_issue_query_default_sorting_string_short').destroy_all
    EasySetting.where(:name => 'easy_issue_query_default_sorting_string_long').destroy_all
    EasySetting.where(:name => 'easy_issue_query_list_default_columns').destroy_all
    EasySetting.where(:name => 'easy_user_query_list_default_columns').destroy_all
    EasySetting.where(:name => 'easy_project_query_list_default_columns').destroy_all
  end
end
