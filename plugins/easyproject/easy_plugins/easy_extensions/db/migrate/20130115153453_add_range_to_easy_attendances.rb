class AddRangeToEasyAttendances < ActiveRecord::Migration
  def change
    add_column :easy_attendances, :range, :integer
  end
end
