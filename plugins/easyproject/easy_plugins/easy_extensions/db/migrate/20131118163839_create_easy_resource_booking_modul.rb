class CreateEasyResourceBookingModul < ActiveRecord::Migration
  def up
    page = EasyPage.page_my_page.dup
    page.page_name = 'easy-resource-booking-module'
    page.save

    EasyPageAvailableZone.ensure_easy_page_available_zone page, EasyPageZone.find_by_zone_name('top-middle')
    EasyPageAvailableZone.ensure_easy_page_available_zone page, EasyPageZone.find_by_zone_name('middle-left')
    EasyPageAvailableZone.ensure_easy_page_available_zone page, EasyPageZone.find_by_zone_name('middle-right')

    EpmResourceAvailability.install_to_page('easy-resource-booking-module')
    EasySetting.create(:name => :show_easy_resource_booking, :value => true)
  end

  def down
    EasyPage.where(:page_name => 'easy-resource-booking-module').destroy_all
    EasySetting.where(:name => 'show_easy_resource_booking').destroy_all
  end
end
