class ChangeIssueDescriptionToLongText < ActiveRecord::Migration
  def up
    adapter_name = Issue.connection_config[:adapter]
    case adapter_name.downcase
    when 'mysql', 'mysql2'
      change_column :issues, :description, :text, {:limit => 4294967295, :default => nil}
    end
  end

  def down
  end
end
