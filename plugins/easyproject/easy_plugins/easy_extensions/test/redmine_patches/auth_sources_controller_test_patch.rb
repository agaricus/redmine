require File.expand_path('../redmine_test_patch', __FILE__)

module EasyExtensions
  module AuthSourcesControllerTestPatch
    extend RedmineTestPatch

    repair_test :test_destroy_auth_source_in_use do
      User.find(2).update_attribute :auth_source_id, 1

      assert_no_difference 'AuthSourceLdap.count' do
        delete :destroy, :id => 1
        assert_redirected_to :action => 'move_users', :id => 1
      end
    end

  end
end
