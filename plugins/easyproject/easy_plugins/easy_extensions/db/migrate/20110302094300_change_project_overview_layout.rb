class ChangeProjectOverviewLayout < ActiveRecord::Migration
  def self.up
    EasyPage.reset_column_information
    EasyPageZone.reset_column_information
    EasyPageAvailableZone.reset_column_information

    page = EasyPage.find_by_page_name('project-overview')

    EasyPageAvailableZone.ensure_easy_page_available_zone page, EasyPageZone.find_by_zone_name('bottom-left')

    page.layout_path = 'easy_page_layouts/two_column_header_three_rows_right_sidebar'
    page.save!
  end

  def self.down
  end
end
