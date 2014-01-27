require File.expand_path('../../spec_helper', __FILE__)
feature 'User customize easy page' do

  let(:user) { FactoryGirl.create(:user) }
  let(:admin_user) { FactoryGirl.create(:admin_user) }
  let(:project) { FactoryGirl.create(:project) }


  context 'my-page customization' do

    before(:each) { logged_user( user ) }

    scenario 'add module noticeboard', :js => true do
      visit '/my/page_layout'
      within '#block-form' do
        select "Noticeboard", :from => "block-select"
        find('.add-module-button').click
      end
      content = find('.module-content')
      sleep(1) #bad solution of bug with dirty checking... CKEDITOR not ready yet maybe?
      text = 'Some testing text to the noticeboard'
      fill_in_ckeditor(1, :context=>'.module-content', :with => text)
      find('.save-modules-back').click
      page.should have_content(text)
    end

  end

  context 'project-page customization' do

    before(:each) do
      logged_user( admin_user )
    end

    scenario 'add module noticeboard', :js => true do
      visit url_for({:controller => 'projects', :action => 'personalize_show', :id => project, :only_path => true})

      within '#block-form' do
        select "Noticeboard", :from => "block-select"
        find('.add-module-button').click
      end
      content = find('.module-content')
      content.fill_in('Heading', :with => 'TEST')
      sleep(1) #bad solution of bug with dirty checking... CKEDITOR not ready yet maybe?
      text = 'Some testing text to the noticeboard'
      fill_in_ckeditor(1, :context=>'.module-content', :with => text)
      find('.save-modules-back').click
      page.should have_content('TEST')
      page.should have_content(text)
    end

  end

end
