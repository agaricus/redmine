class CreateEpmProjectHistoryModule < ActiveRecord::Migration
  def self.up
    EpmProjectHistory.install_to_page('project-overview')
  end

  def self.down
    EpmProjectHistory.destroy_all
  end

end