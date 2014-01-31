class EasyAgileBoardController < ApplicationController

  before_filter :find_project
  before_filter :authorize

  helper :easy_query
  include EasyQueryHelper
  helper :issues

  def show
    retrieve_query(EasyAgileBoardQuery)
    issues = Issue.arel_table
    @query.add_additional_statement(
      issues[:id].not_in(@project.issue_easy_sprint_relations.pluck(:issue_id)).to_sql
    )

    @backlog = @query.entities(limit: 25)
  end

end
