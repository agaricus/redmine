class ChangeIssueDefaultSortsBack < ActiveRecord::Migration
  def up
    EasySetting.where(:name => 'issue_default_sorting_string_long').each do |e|
      e.update_attributes(:value => "#{IssuePriority.table_name}.position DESC, #{Issue.table_name}.due_date,  #{Issue.table_name}.root_id,  #{Issue.table_name}.lft")
    end
    EasySetting.where(:name => 'issue_default_sorting_array').each do |e|
      e.update_attributes(:value => [['priority','desc'],'due_date','parent'])
    end
    EasySetting.where(:name => 'issue_default_sorting_string_short').each do |e|
      e.update_attributes(:value => 'priority:desc,due_date,parent:asc')
    end
  end

  def down
  end
end
