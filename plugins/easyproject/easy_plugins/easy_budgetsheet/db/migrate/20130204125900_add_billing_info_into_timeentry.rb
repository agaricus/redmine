class AddBillingInfoIntoTimeentry < ActiveRecord::Migration
  def self.up

    add_column :time_entries, :easy_is_billable, :boolean, {:default => true, :null => false}
    add_column :time_entries, :easy_billed, :datetime, {:null => true}

  end

  def self.down

    remove_column :time_entries, :easy_is_billable
    remove_column :time_entries, :easy_billed

  end
end
