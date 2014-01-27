class AddIndexEasyMoneyRatesOnProjectIdAndRateTypeIdAndEntityTypeAndEntityId < ActiveRecord::Migration
  def self.up
    add_index :easy_money_rates, [:project_id, :rate_type_id, :entity_type, :entity_id], :name => :index_easy_money_rates_on_project_id_and_rate_type_and_entity
  end

  def self.down
    remove_index :easy_money_rates, :name => :index_easy_money_rates_on_project_id_and_rate_type_and_entity
  end
end