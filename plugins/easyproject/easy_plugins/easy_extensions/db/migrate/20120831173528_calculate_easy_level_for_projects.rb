class CalculateEasyLevelForProjects < ActiveRecord::Migration
	def self.up
    Project.reset_column_information

    Project.all.each do |project|
      project.update_column(:easy_level, project.level)
    end
  end

  def self.down
    Project.all.each do |project|
      project.update_column(:easy_level, nil)
    end
  end
end