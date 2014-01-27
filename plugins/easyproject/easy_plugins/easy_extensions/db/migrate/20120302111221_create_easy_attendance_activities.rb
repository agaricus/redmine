class CreateEasyAttendanceActivities < ActiveRecord::Migration
  def self.up
    create_table :easy_attendance_activities do |t|
      t.column :name, :string, :null => false
      t.column :position, :integer, :null => true, :default => 1
      t.column :at_work, :boolean, :default => false
      t.column :is_default, :boolean, :default => false, :null => false
      t.column :internal_name, :string, :null => true
      t.column :non_deletable, :boolean, :null => false, :default => false
      
      t.timestamps
    end
  end

  def self.down
    drop_table :easy_attendance_activities
  end
end
