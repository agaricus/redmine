require File.expand_path('../redmine_test_patch', __FILE__)

module EasyExtensions
  module CustomFieldsControllerTestPatch
    extend RedmineTestPatch

    repair_test :test_new_issue_custom_field do
      get :new, :type => 'IssueCustomField'
      assert_response :success
      assert_template 'new'
      assert_select 'form#custom_field_form' do
        assert_select 'select#custom_field_field_format[name=?]', 'custom_field[field_format]' do
          assert_select 'option[value=user]', :text => 'User'
          assert_select 'option[value=version]', :text => 'Milestone'
        end
        assert_select 'input[type=hidden][name=type][value=IssueCustomField]'
      end
    end

  end
end
