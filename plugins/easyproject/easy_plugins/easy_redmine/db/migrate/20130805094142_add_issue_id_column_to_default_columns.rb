class AddIssueIdColumnToDefaultColumns < ActiveRecord::Migration
  def up
    easy_setting = EasySetting.where(:name => 'easy_issue_query_list_default_columns').first
    if easy_setting && !easy_setting.value.include?('id')
      easy_setting.value.unshift('id')
      easy_setting.save
    end
  end

  def down
  end
end
