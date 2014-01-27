require File.expand_path('../../spec_helper', __FILE__)

describe EasyPageLayoutController do

  before(:all) {
    @my_page_id = 1
  }

  let(:user) { FactoryGirl.create(:user) }
  let(:available_module) { EasyPageAvailableModule.where(:easy_pages_id => @my_page_id).first }

  describe 'add_module' do
    before(:each) { logged_user( user ) }

    it 'creates a new module on user page' do
      expect {
        post :add_module, :page_id => @my_page_id, :zone_id => 1, :user_id => user.id, :module_id => available_module.id
      }.to change(EasyPageZoneModule.where(:user_id => user.id), :count).by(1)
    end

    it 'render a module template' do
      post :add_module, :page_id => @my_page_id, :zone_id => 1, :user_id => user.id, :module_id => EpmMyCalendar.first.id
      response.should render_template "easy_page_layout/_page_module_edit_container"
    end
  end

end