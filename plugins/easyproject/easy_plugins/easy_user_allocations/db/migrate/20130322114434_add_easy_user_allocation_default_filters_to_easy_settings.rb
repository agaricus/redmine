class AddEasyUserAllocationDefaultFiltersToEasySettings < ActiveRecord::Migration
  def change
    EasySetting.create(:name => 'easy_user_allocation_query_default_filters', :value => {
      'range'=>{:operator=>'date_period_1', :values=>HashWithIndifferentAccess.new({:period => 'next_90_days', :from => '', :to => ''})},
      'issue_status_id' => {:operator => 'o', :values => ['1']},
      'issue_is_planned' => {:operator => '=', :values => ['0']},
      'user_status'=>{:operator=>'=', :values => [User::STATUS_ACTIVE.to_s]}
    })
  end
end
