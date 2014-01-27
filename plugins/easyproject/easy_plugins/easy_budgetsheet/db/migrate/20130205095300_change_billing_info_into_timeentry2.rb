class ChangeBillingInfoIntoTimeentry2 < ActiveRecord::Migration
  def self.up

    remove_column :time_entries, :easy_billed
    add_column :time_entries, :easy_billed, :boolean, {:null => false, :default => false}

  end

  def self.down

  end
end
