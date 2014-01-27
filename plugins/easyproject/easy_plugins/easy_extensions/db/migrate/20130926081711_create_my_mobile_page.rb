class CreateMyMobilePage < ActiveRecord::Migration
  def up
    page = EasyPage.page_my_page.dup
    page.page_name = 'my-mobile-page'
    page.save

    EasyPageAvailableZone.ensure_easy_page_available_zone page, EasyPageZone.find_by_zone_name('top-middle')
    EasyPageAvailableZone.ensure_easy_page_available_zone page, EasyPageZone.find_by_zone_name('middle-left')
    EasyPageAvailableZone.ensure_easy_page_available_zone page, EasyPageZone.find_by_zone_name('middle-right')

  end

  def down
    EasyPage.where(:page_name => 'my-mobile-page').destroy_all
    EpmMobileIssueQuery.destroy_all
  end
end
