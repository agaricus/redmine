require File.expand_path('../../../../../easy_extensions/test/spec/spec_helper', __FILE__)

describe BudgetsheetController do

  let(:projects) do
    FactoryGirl.create_list(:project, 3)
  end
  let(:issues) do
    result = projects.map do |project|
      FactoryGirl.create_list(:issue, 4, :project => project)
    end
    result.flatten
  end

  subject(:time_entries) do
    time_entries = []
    issues.each_with_index do |issue, index|
      next if index % 2 == 0
      time_entries << FactoryGirl.create(:time_entry, :issue => issue )
    end
    time_entries += FactoryGirl.create_list(:time_entry, 3, :issue => issues.first )
  end

  before(:each) do
    time_entries # touch it for ensure they are created
  end

  describe 'GET /budgetsheet' do

    before(:all) { User.stubs(:current).returns( FactoryGirl.build(:admin_user) ) }

    it 'should assign query' do
      get :index
      assigns(:query)
    end

  end

end
