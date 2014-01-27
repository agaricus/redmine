class AddFixedActivity < ActiveRecord::Migration
  def self.up
    EasySetting.create(:name => 'project_fixed_activity', :value => 'false')
    add_column(:issues, :activity_id, :integer, :null => true) unless column_exists?(:issues, :activity_id, :integer)
  end

  def self.down
    EasySetting.where(:name => 'project_fixed_activity').destroy_all
    remove_column :issues, :activity_id
  end
end