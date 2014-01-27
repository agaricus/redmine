require File.expand_path('../redmine_test_patch', __FILE__)

module EasyExtensions
  module UsersControllerTestPatch
    extend RedmineTestPatch

    repair_test :test_create_membership do
      assert_difference 'Member.count' do
        post :edit_membership, :id => 7, :membership => { :project_ids => [3], :role_ids => [2]}
      end
      assert_redirected_to :action => 'edit', :id => '7', :tab => 'memberships'
      member = Member.first(:order => 'id DESC')
      assert_equal User.find(7), member.principal
      assert_equal [2], member.role_ids
      assert_equal 3, member.project_id
    end

    repair_test :test_create_membership_js_format do
      assert_difference 'Member.count' do
        post :edit_membership, :id => 7, :membership => {:project_ids => [3], :role_ids => [2]}, :format => 'js'
        assert_response :success
        assert_template 'edit_membership'
        assert_equal 'text/javascript', response.content_type
      end
      member = Member.first(:order => 'id DESC')
      assert_equal User.find(7), member.principal
      assert_equal [2], member.role_ids
      assert_equal 3, member.project_id
      assert_include 'tab-content-memberships', response.body
    end

    repair_test :test_index do
      get :index
      assert_response :success
      assert_template 'index'
      assert_not_nil assigns(:users)
    end

    repair_test :test_index_with_group_filter do
      get :index, :set_filter => '1', :groups => '10'
      assert_response :success
      assert_template 'index'
      users = assigns(:users).values[0][:entities]
      assert users.any?
      assert_equal([], (users - Group.find(10).users))
    end

    repair_test :test_index_with_status_filter do
      get :index, :set_filter => '1', :status => 3
      assert_response :success
      assert_template 'index'
      users = assigns(:users).values[0][:entities]
      assert_not_nil users
      assert_equal [3], users.map(&:status).uniq
    end

    repair_test :test_index_with_name_filter do
      get :index, :set_filter => '1', :firstname => 'john'
      assert_response :success
      assert_template 'index'
      users = assigns(:users).values[0][:entities]
      assert_not_nil users
      assert_equal 1, users.size
      assert_equal 'John', users.first.firstname
    end

  end
end
