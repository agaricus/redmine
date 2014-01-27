class DeleteEasyAttendanceWithoutUser < ActiveRecord::Migration
  def up
    EasyAttendance.where(["user_id NOT IN (?)", User.all.collect(&:id)]).each do |e|
      e.delete
    end
  end

  def down
  end
end
