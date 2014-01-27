# Class for fulltext searching in OPEN issues
class IssueOpen < Issue
  searchable_options[:include] << :status

  def self.searchable_options
    options = Issue.searchable_options
    options[:additional_conditions] = "#{Project.table_name}.easy_is_easy_template = #{connection.quoted_false} AND #{IssueStatus.table_name}.is_closed = #{connection.quoted_false}"
    
    return options
  end

  def self.name
	'Issue'
  end
end