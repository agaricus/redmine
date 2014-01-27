class CreateEasyMoneyPageAsModifiable < ActiveRecord::Migration
  def self.up
    page = EasyPage.create!(:page_name => 'easy-money-projects-overview', :layout_path => "easy_page_layouts/two_column_header_three_rows_right_sidebar")

    EasyPageAvailableZone.ensure_easy_page_available_zone page, EasyPageZone.find_by_zone_name('top-left')
    EasyPageAvailableZone.ensure_easy_page_available_zone page, EasyPageZone.find_by_zone_name('middle-left')
    EasyPageAvailableZone.ensure_easy_page_available_zone page, EasyPageZone.find_by_zone_name('middle-right')
    EasyPageAvailableZone.ensure_easy_page_available_zone page, EasyPageZone.find_by_zone_name('bottom-left')
    EasyPageAvailableZone.ensure_easy_page_available_zone page, EasyPageZone.find_by_zone_name('right-sidebar')

    EpmNoticeboard.install_to_page('easy-money-projects-overview')
  end

  def self.down
    EasyPage.where(:page_name => 'easy-money-projects-overview').destroy_all
  end
end