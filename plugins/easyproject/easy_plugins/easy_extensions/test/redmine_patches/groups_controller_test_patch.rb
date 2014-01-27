require File.expand_path('../redmine_test_patch', __FILE__)

module EasyExtensions
  module GroupsControllerTestPatch
    extend RedmineTestPatch

    repair_test :test_edit do
      get :edit, :id => 10
      assert_response :success
      assert_template 'edit'

      assert_select 'div#tab-content-general'
      assert_select 'a[href=/groups/10/edit?tab=users]'
      assert_select 'a[href=/groups/10/edit?tab=memberships]'
    end

    repair_test :test_new_membership do
      assert_difference 'Group.find(10).members.count' do
        post :edit_membership, :id => 10, :membership => {:project_ids => [2], :role_ids => ['1', '2']}
      end
    end

    repair_test :test_xhr_new_membership do
      assert_difference 'Group.find(10).members.count' do
        xhr :post, :edit_membership, :id => 10, :membership => {:project_ids => [2], :role_ids => ['1', '2']}
        assert_response :success
        assert_template 'edit_membership'
        assert_equal 'text/javascript', response.content_type
      end
      assert_match /OnlineStore/, response.body
    end

  end
end
