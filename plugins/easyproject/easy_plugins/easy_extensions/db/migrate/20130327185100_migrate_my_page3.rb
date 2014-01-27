require_dependency 'utils/blockutils'

class MigrateMyPage3 < ActiveRecord::Migration
  extend EasyUtils::BlockUtils

  def self.up
    EasyPage.reset_column_information
    EasyPageAvailableZone.reset_column_information
    EasyPageZone.reset_column_information
    EasyPageModule.reset_column_information
    User.reset_column_information

    somebody_migrated = !!User.all.detect{|u| u.pref.others && u.pref.others[:my_page_layout_migrated]}

    unless somebody_migrated
      my_page = EasyPage.find_by_page_name('my-page')

      User.all.each do |user|
        user_pref = user.pref.others

        unless user_pref[:my_page_layout_migrated]
          my_page_layout = user_pref[:my_page_layout] || {}
          my_page_layout_settings = user_pref[:my_page_layout_settings] || {}

          zone_top_middle = EasyPageAvailableZone.find_by_easy_pages_id_and_easy_page_zones_id(my_page.id, EasyPageZone.find_by_zone_name('top-middle').id)
          unless zone_top_middle.nil?
            migrate_my_page_zone(my_page, zone_top_middle, user, my_page_layout["top"] || [], my_page_layout_settings)
          end

          zone_middle_left = EasyPageAvailableZone.find_by_easy_pages_id_and_easy_page_zones_id(my_page.id, EasyPageZone.find_by_zone_name('middle-left').id)
          unless zone_middle_left.nil?
            migrate_my_page_zone(my_page, zone_middle_left, user, my_page_layout["left"] || [], my_page_layout_settings)
          end

          zone_middle_right = EasyPageAvailableZone.find_by_easy_pages_id_and_easy_page_zones_id(my_page.id, EasyPageZone.find_by_zone_name('middle-right').id)
          unless zone_middle_right.nil?
            migrate_my_page_zone(my_page, zone_middle_right, user, my_page_layout["right"] || [], my_page_layout_settings)
          end

          user_pref[:my_page_layout_migrated] = true
          user_pref.delete(:my_page_layout)
          user_pref.delete(:my_page_layout_settings)
          user.pref.others = user_pref
          user.pref.save
        end
      end

    end
  end

  def self.migrate_my_page_zone(my_page, available_zone, user, blocks, my_page_layout_settings)
    position = 0

    blocks.each do |block_name|
      position += 1

      module_definition = nil

      case block_name
      when "issuesreportedbyme"
        module_definition = EpmIssuesReportedByMe.first
      when "issuesassignedtome"
        module_definition = EpmIssuesAssignedToMe.first
      when "issueswatchedbyme", "issueswatched"
        module_definition = EpmIssuesWatchedByMe.first
      when "documents"
        module_definition = EpmDocuments.first
      when "news"
        module_definition = EpmNews.first
      when "calendar"
        module_definition = EpmMyCalendar.first
      when "timelog"
        module_definition = EpmTimelogSimple.first
      end

      unless module_definition.nil?
        available_module = EasyPageAvailableModule.find_by_easy_pages_id_and_easy_page_modules_id(my_page.id, module_definition.id)

        unless available_module.nil?
          page_module = EasyPageZoneModule.new(:easy_pages_id => my_page.id, :easy_page_available_zones_id => available_zone.id, :easy_page_available_modules_id => available_module.id, :user_id => user.id, :position => position)
          page_module.settings = my_page_layout_settings[block_name] || {}

          page_module.save!
        end
      end
    end
  end

end