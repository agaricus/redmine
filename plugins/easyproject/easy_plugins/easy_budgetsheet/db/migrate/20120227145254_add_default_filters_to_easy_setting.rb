class AddDefaultFiltersToEasySetting < ActiveRecord::Migration
  def self.up
    EasySetting.create(:name => 'easy_budget_sheet_query_default_filters', :value => {'spent_on' => {:operator => 'date_period_1', :values => {:from =>  '', :period => 'last_month', :to => ''}}})
  end

  def self.down
  end
end
