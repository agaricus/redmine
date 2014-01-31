require File.expand_path('../../../../../easy_extensions/test/spec/spec_helper', __FILE__)

describe EasySprintsController do

  render_views

  let(:project) { FactoryGirl.create(:project) }
  let(:sprint) { FactoryGirl.create(:easy_sprint) }
  let(:sprints) { FactoryGirl.create_list(:easy_sprint, 3, project: project) }
  let(:issue)  { FactoryGirl.create(:issue) }

  context 'with anonymous user' do
  end

  context 'with admin user' do
    before(:each) { logged_user(FactoryGirl.create(:admin_user)) }

    describe 'GET new' do
      it 'renders 404 for standard requests' do
        get :new, :project_id => project.id
        assert_response :missing
      end
      it 'renders form for XHR requests' do
        xhr :get, :new, :project_id => project.id
        assert_response :success
        response.body.should have_selector('form.easy-sprint')
        response.body.should_not have_selector('#content')
      end
    end

    describe 'POST create (json xhr)' do
      it 'creates a sprint' do
        sprint_attrs = FactoryGirl.attributes_for(:easy_sprint)
        expect {xhr :post, :create, project_id: project.id, format: 'json', easy_sprint: sprint_attrs}.to change(EasySprint, :count).by(1)

        sprint = EasySprint.last
        sprint.project.should    == project
        sprint.start_date.should == sprint_attrs[:start_date]
        sprint.due_date.should   == sprint_attrs[:due_date]
      end

      it "renders validation errors if attributes are not valid" do
        expect {xhr :post, :create, project_id: project.id, format: 'json', easy_sprint: {:start_date => Date.today}}.not_to change(EasySprint, :count)
        response.status.should == 422
        json = ActiveSupport::JSON.decode(response.body)
        json['errors'][0].should include("Name can't be blank")
      end
    end

    describe 'GET index (xhr)' do
      it 'renders existing sprints' do
        sprints
        xhr :get, :index, :project_id => project.id
        assert_response :success
        response.body.should have_selector('div.easy-sprint', count: 3)
        response.body.should_not have_selector('#content')
      end
    end

    describe 'GET edit (xhr)' do
      it 'renders sprint form without layout' do
        xhr :get, :edit, project_id: sprint.project_id, id: sprint.id
        assert_response :success
        response.body.should have_selector('form.easy-sprint')
        response.body.should_not have_selector('#content')
      end
    end

    describe 'PUT update (xhr)' do
      it 'updates the sprint' do
        xhr :put, :update, project_id: sprint.project_id, id: sprint.id, easy_sprint: {name: 'New name'}
        assert_response :success
        sprint.reload
        sprint.name.should == 'New name'
      end

      it 'renders validation errors if params are invalid' do
        xhr :put, :update, project_id: sprint.project_id, id: sprint.id, easy_sprint: {name: ''}, format: 'json'
        response.status.should == 422
        JSON.parse(response.body).should == { "errors" => ["Name can't be blank"] }
      end
    end

    describe 'DELETE destroy (xhr)' do
      it 'destroys the sprint' do
        sprint
        expect { xhr :delete, :destroy, project_id: sprint.project_id, id: sprint.id }.to change {EasySprint.count}.by(-1)
      end
    end

    describe 'POST assign_issue' do
      it 'assigns the issue to a sprint' do
        xhr :post, :assign_issue, project_id: sprint.project_id, id: sprint.id, issue_id: issue.id
        assert_response :success
        EasySprint.last.issue_ids == [Issue.last.id]
      end
    end

  end

end
