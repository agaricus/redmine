require File.expand_path('../../test_helper', __FILE__)

class TemplatesControllerTest < ActionController::TestCase
  #fixtures :projects, :users, :members, :member_roles, :roles, :groups_users
  easy_fixtures :projects

  def setup
    @request.session[:user_id] = 1
  end

  def test_index
    get :index
    assert_response :success
    assert_template 'index'
  end

  def test_index2
    get :index
    assert_response :success
    assert_template 'index'
  end

  def test_index3
    get :index
    assert_response :success
    assert_template 'index'
  end

  def test_index4
    get :index
    assert_response :success
    assert_template 'index'
  end
end
