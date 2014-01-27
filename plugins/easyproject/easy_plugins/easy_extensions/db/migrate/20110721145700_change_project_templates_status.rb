class ChangeProjectTemplatesStatus < ActiveRecord::Migration
  def self.up
    Project.where(:easy_is_easy_template => true).where(:status => 0).update_all(:status => Project::STATUS_ACTIVE)
  end

  def self.down
  end
end
