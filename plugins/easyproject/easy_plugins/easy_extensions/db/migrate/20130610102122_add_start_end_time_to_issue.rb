class AddStartEndTimeToIssue < ActiveRecord::Migration
  def change
    add_column :issues, :easy_start_date_time, :datetime
  end
end
