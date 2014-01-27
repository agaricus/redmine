class ChangeBillingInfoIntoTimeentry3 < ActiveRecord::Migration
  def self.up

    change_column :time_entries, :easy_billed, :boolean, {:null => false, :default => false}

  end

  def self.down

  end
end
