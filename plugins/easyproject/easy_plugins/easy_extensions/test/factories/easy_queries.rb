FactoryGirl.define do

  factory :easy_query do
    name 'Test query'

  end

  factory :easy_issue_query, :parent => :easy_query, :class => 'EasyIssueQuery' do
    name 'TestIssueQuery'
  end

  factory :easy_budget_sheet_query, :parent => :easy_query, :class => 'EasyBudgetSheetQuery' do
    name 'TestBudgetSheetQuery'

    column_names ['project', 'issue', 'spent_on', 'user', 'hours', 'estimated_hours']
  end

end
