class CreateEasyMoneyPageAsModifiable2 < ActiveRecord::Migration
  def self.up
    page = EasyPage.where(:page_name => 'easy-money-projects-overview').first

    EasyPageAvailableZone.ensure_easy_page_available_zone page, EasyPageZone.find_by_zone_name('bottom-left')
  end

  def self.down
  end
end