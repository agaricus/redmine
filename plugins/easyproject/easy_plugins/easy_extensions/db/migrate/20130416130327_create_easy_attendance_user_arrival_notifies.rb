class CreateEasyAttendanceUserArrivalNotifies < ActiveRecord::Migration
  def up
    create_table :easy_attendance_user_arrival_notifies, :force => true do |t|
      t.references :user
      t.references :notify_to

      t.text :message

      t.timestamps
    end

    add_index :easy_attendance_user_arrival_notifies, [:user_id, :notify_to_id], :name => :easy_attendance_user_arrival_notify_notify_id_x_user_id
    add_index :easy_attendance_user_arrival_notifies, [:notify_to_id, :user_id], :name => :easy_attendance_user_arrival_notify_user_id_x_notify_id
  end

  def down
    drop_table :easy_attendance_user_arrival_notifies
  end
end
