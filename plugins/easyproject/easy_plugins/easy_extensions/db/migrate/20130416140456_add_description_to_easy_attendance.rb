class AddDescriptionToEasyAttendance < ActiveRecord::Migration
  def change
    add_column :easy_attendances, :description, :text
  end
end
