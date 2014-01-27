class AddIndexEasyMoneyRatePrioritiesOnProjectIdAndRateTypeId < ActiveRecord::Migration
  def self.up
    add_index :easy_money_rate_priorities, [:project_id, :rate_type_id], :name => :index_easy_money_rate_priorities_on_user_id_and_project_id
  end

  def self.down
    remove_index :easy_money_rate_priorities, :name => :index_easy_money_rate_priorities_on_user_id_and_project_id
  end
end