class MigrateEasyQuery < EasyExtensions::EasyDataMigration
  def self.up
    Query.reset_column_information
    ProjectQuery.reset_column_information
    UserQuery.reset_column_information
    EasyQuery.reset_column_information

    migrate_issue_query
    migrate_time_entry_query
    migrate_project_query
    migrate_user_query
  end

  def self.down
  end

  def self.migrate_issue_query
    IssueQuery.all.each do |query|
      nq = query.to_new_easy_query

      if nq.save(:validate => false)
        query.destroy
      end
    end
  end

  def self.migrate_time_entry_query
    TimeEntryQuery.all.each do |query|
      nq = query.to_new_easy_query

      if nq.save(:validate => false)
        query.destroy
      end
    end
  end

  def self.migrate_project_query
    ProjectQuery.all.each do |query|
      nq = query.to_new_easy_query

      if nq.save(:validate => false)
        query.destroy
      end
    end
  end

  def self.migrate_user_query
    UserQuery.all.each do |query|
      nq = query.to_new_easy_query

      if nq.save(:validate => false)
        query.destroy
      end
    end
  end
end
