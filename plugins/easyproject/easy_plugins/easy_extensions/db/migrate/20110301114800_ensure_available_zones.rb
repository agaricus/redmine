class EnsureAvailableZones < ActiveRecord::Migration
  def self.up
    EasyPage.reset_column_information
    EasyPageZone.reset_column_information
    EasyPageAvailableZone.reset_column_information

    page = EasyPage.find_by_page_name('my-page')

    EasyPageAvailableZone.ensure_easy_page_available_zone page, EasyPageZone.find_by_zone_name('top-middle')
    EasyPageAvailableZone.ensure_easy_page_available_zone page, EasyPageZone.find_by_zone_name('middle-left')
    EasyPageAvailableZone.ensure_easy_page_available_zone page, EasyPageZone.find_by_zone_name('middle-right')

    page = EasyPage.find_by_page_name('project-overview')

    EasyPageAvailableZone.ensure_easy_page_available_zone page, EasyPageZone.find_by_zone_name('top-left')
    EasyPageAvailableZone.ensure_easy_page_available_zone page, EasyPageZone.find_by_zone_name('middle-left')
    EasyPageAvailableZone.ensure_easy_page_available_zone page, EasyPageZone.find_by_zone_name('middle-right')
    EasyPageAvailableZone.ensure_easy_page_available_zone page, EasyPageZone.find_by_zone_name('right-sidebar')

    EasyPageAvailableZone.delete_easy_page_available_zone page, EasyPageZone.find_by_zone_name('top-middle')

    EasyPage.reset_column_information
    EasyPageAvailableZone.reset_column_information

    EasyPage.all.each do |page|
      page.zones.each_with_index do |zone, zone_idx|
        zone.position = (zone_idx + 1)
        zone.save
      end
    end

    EasyPage.reset_column_information
    EasyPageZone.reset_column_information
    EasyPageAvailableZone.reset_column_information

    page = EasyPage.find_by_page_name('my-page')
    zone = EasyPageZone.find_by_zone_name('top-middle')
    available_zone = EasyPageAvailableZone.find_by_easy_pages_id_and_easy_page_zones_id(page.id, zone.id)
    available_zone.move_to_top

    page = EasyPage.find_by_page_name('project-overview')
    zone = EasyPageZone.find_by_zone_name('top-left')
    available_zone = EasyPageAvailableZone.find_by_easy_pages_id_and_easy_page_zones_id(page.id, zone.id)
    available_zone.move_to_top
  end

  def self.down
  end
end
