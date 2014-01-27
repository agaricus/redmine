class ChangeBillingInfoIntoTimeentry < ActiveRecord::Migration
  def self.up

    remove_column :time_entries, :easy_billed
    add_column :time_entries, :easy_billed, :boolean, {:default => true, :null => false}

  end

  def self.down

  end
end
