feature 'Time entry query view' do

  let(:projects) do
    FactoryGirl.create_list(:project, 3)
  end
  let(:issues) do
    result = projects.map do |project|
      FactoryGirl.create_list(:issue, 4, :project => project)
    end
    result.flatten
  end
  let(:query) do
    FactoryGirl.create(:easy_budget_sheet_query)
  end
  let(:settings) do
    {
      'easy_budget_sheet_query_list_default_columns' => ['project', 'issue', 'spent_on', 'user', 'hours', 'estimated_hours'],
      'easy_budget_sheet_query_default_filters' => {}
    }
  end

  subject do
    time_entries = []
    issues.each_with_index do |issue, index|
      next if index % 2 == 0
      time_entries << FactoryGirl.create(:time_entry, :issue => issue )
    end
    time_entries += FactoryGirl.create_list(:time_entry, 3, :issue => issues.first )
  end

  before(:all) { logged_user( FactoryGirl.create(:admin_user) ) }
  
  scenario 'User check the sums last month', :js => true, :slow => true do
    hours = subject.sum{|te| te.hours }
    estimated_hours = issues.sum{|i| i.time_entries.any? ? i.estimated_hours : 0 }
    
    # with_easy_settings(settings) do
    visit "/budgetsheet?query_id=#{query.id}"
    page.find('#totalsum-summary td.hours').text.should have_content(hours.to_s)
    page.find('#totalsum-summary td.estimated_hours').text.should have_content(estimated_hours.to_s)
    # end
  end

end