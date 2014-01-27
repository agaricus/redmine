class CreateEasyAttendances < ActiveRecord::Migration
  def self.up
    create_table :easy_attendances do |t|
      t.column :arrival, :datetime, :null => true
      t.column :departure, :datetime, :null => true
      t.column :user_id, :integer, :null => false
      t.column :easy_attendance_activity_id, :integer, :null => true
      t.column :edited_by_id, :integer, :null => true
      t.column :edited_when, :datetime, :null => true
      t.column :locked, :boolean, :default => false
      
      t.timestamps
    end
    
    add_index :easy_attendances, :user_id
    add_index :easy_attendances, [:user_id, :departure]
  end

  def self.down
    drop_table :easy_attendances
  end
end
