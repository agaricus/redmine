require File.expand_path('../../spec_helper', __FILE__)

describe IssuesController do

  before(:each) {logged_user(FactoryGirl.create(:admin_user))} # admin

  let(:project) {FactoryGirl.create(:project)}

  it 'exports index to pdf' do
    get :index, :format => 'pdf'
    assert_response :success
    assert_not_nil assigns(:issues)
    assert_equal 'application/pdf', @response.content_type

    get :index, :project_id => project.id, :format => 'pdf'
    assert_response :success
    assert_not_nil assigns(:issues)
    assert_equal 'application/pdf', @response.content_type
  end

end
