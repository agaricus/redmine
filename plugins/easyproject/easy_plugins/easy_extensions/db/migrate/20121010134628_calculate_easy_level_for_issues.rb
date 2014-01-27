class CalculateEasyLevelForIssues < ActiveRecord::Migration
	def self.up
    Issue.reset_column_information

    Issue.all.each do |issue|
      issue.update_column(:easy_level, issue.level)
    end
  end

  def self.down
    Issue.all.each do |issue|
      issue.update_column(:easy_level, nil)
    end
  end
end