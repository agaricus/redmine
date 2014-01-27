require File.expand_path('../../spec_helper', __FILE__)

describe BulkTimeEntriesController do

  let(:project) do
    FactoryGirl.create(:project)
  end
  let(:issue) do
    FactoryGirl.create(:issue, :project => project)
  end

  describe 'POST /bulk_time_entries' do

    before(:all) { User.stubs(:current).returns( FactoryGirl.build(:admin_user) ) }

    it 'create time_entry' do
      post :save, {:user_id => User.current.id, :project_id => project.id, :spent_on => Date.today.to_s, :time_entry => {:hours => nil, :easy_time_entry_range => {:from => "10.00", :to => "11:30"}, :activity_id => project.time_entry_activity_ids.first, :comments => "Bla Bla"}}
    end

  end

end
