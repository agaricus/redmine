require 'fileutils'
Dir[File.dirname(__FILE__) + '/importables/*.rb'].each {|file| require file }

module EasyXmlData
  class Importer

    include Singleton

    def initialize()
      @id_mappings = {}
      @xml = nil
      @importables = []
      @notifications = false
      @manual_mapping = []
    end

    attr_writer :notifications

    def archive_file=(archive_file)
      clear_import_dir
      archive = Zip::ZipFile.open(archive_file)
      Zippy.list(archive_file).each do |file|
        if file.starts_with?('attachments/')
          destination = Attachment.storage_path + '/' + file.gsub('attachments/', '')
          archive.extract(file, destination) unless File.exists?(destination)
        else
          archive.extract(file, "#{import_dir}/#{file}")
        end
      end
      self.xml_file = File.open(import_dir + '/data.xml')
    end

    def clear_import_dir
      import_dir = "#{Attachment.storage_path}/easy_xml_data_import_data"
      if File.exists? import_dir
        Dir["#{import_dir}/*"].each{|file| FileUtils.rm_r(file)}
      else
        Dir.mkdir(import_dir)
      end
    end

    def import_dir
      @@import_dir ||= "#{Attachment.storage_path}/easy_xml_data_import_data"
    end

    def xml_file=(xml_file)
      flush
      @xml_file = xml_file
      @xml = Nokogiri::XML(xml_file)
      set_importables
    end

    def import
      if @importables.select{|i| i.mappable? && !i.mapped?}.any?
        raise StandardError, 'Cannot start import until everything is mapped'
      end
      validation_errors = []
      Mailer.with_deliveries(@notifications) do
        @importables.each do |importable|
          validation_errors << importable.import(@id_mappings)
        end
      end
      @xml_file.close if @xml_file && !@xml_file.closed?
      validation_errors.flatten
    end

    def mapping_data
      importable = @importables.detect {|i| i.mappable? && !i.mapped?}
      if importable.blank?
        return nil
      else
        return importable.mapping_data
      end
    end

    def add_map(map, entity_type)
      id_map = {}
      map.each do |map_from, map_to|
        if map_to != ''
          id_map[map_from.to_i] = map_to.to_i
        end
      end
      @id_mappings[entity_type] = id_map
      importable = importable_by_id(entity_type)
      unless importable.blank?
        importable.mapped = true
      end
    end

    def flush
      @xml_file = nil
      initialize
    end

    def importable_by_id(id)
      @importables.detect{|importable| importable.id == id}
    end

    def auto_mappings=(auto_ids)
      auto_ids = auto_ids.dup
      auto_ids = [] unless auto_ids.is_a? Array
      @importables.each do |importable|
        if importable.mappable? && auto_ids.include?(importable.id)
          id, entities_for_mapping, existing_entities = importable.mapping_data
          map = {}
          entities_for_mapping.each do |mapping_data|
            map[mapping_data[:id].to_i] = mapping_data[:match]
          end
          @id_mappings[id] = map
          importable.mapped = true
        end
      end
      ep @id_mappings
      @id_mappings
    end

    private

    def set_importables
      @importables << EasyXmlData::UserImportable.new(:xml => @xml.xpath('//easy_xml_data/users/*'))
      unless (project_custom_fields_xml = @xml.xpath('//easy_xml_data/project-custom-fields/*')).blank?
        @importables << EasyXmlData::ProjectCustomFieldImportable.new(:xml => project_custom_fields_xml)
      end
      unless (issue_custom_fields_xml = @xml.xpath('//easy_xml_data/issue-custom-fields/*')).blank?
        @importables << EasyXmlData::IssueCustomFieldImportable.new(:xml => issue_custom_fields_xml)
      end
      @importables << EasyXmlData::TrackerImportable.new(:xml => @xml.xpath('//easy_xml_data/trackers/*'))
      @importables << EasyXmlData::ProjectImportable.new(:xml => @xml.xpath('//easy_xml_data/projects/*'))
      @importables << EasyXmlData::RoleImportable.new(:xml => @xml.xpath('//easy_xml_data/roles/*'))
      @importables << EasyXmlData::MemberImportable.new(:xml => @xml.xpath('//easy_xml_data/members/*'))
      @importables << EasyXmlData::VersionImportable.new(:xml => @xml.xpath('//easy_xml_data/versions/*'))
      unless (issue_priorities_xml = @xml.xpath('//easy_xml_data/issue-priorities/*')).blank?
        @importables << EasyXmlData::IssuePriorityImportable.new(:xml => issue_priorities_xml)
      end
      unless (issue_statuses_xml = @xml.xpath('//easy_xml_data/issue-statuses/*')).blank?
        @importables << EasyXmlData::IssueStatusImportable.new(:xml => issue_statuses_xml)
      end
      unless (issues_xml = @xml.xpath('//easy_xml_data/issues/*')).blank?
        @importables << EasyXmlData::IssueImportable.new(:xml => issues_xml)
      end
      unless (issue_relations_xml = @xml.xpath('//easy_xml_data/issue-relations/*')).blank?
        @importables << EasyXmlData::IssueRelationImportable.new(:xml => issue_relations_xml)
      end
      unless (workflow_rules_xml = @xml.xpath('//easy_xml_data/workflow_rules/*')).blank?
        @importables << EasyXmlData::WorkflowRuleImportable.new(:xml => workflow_rules_xml)
      end
      unless (news_xml = @xml.xpath('//easy_xml_data/news/*')).blank?
        @importables << EasyXmlData::NewsImportable.new(:xml => news_xml)
      end
      unless (comments_xml = @xml.xpath('//easy_xml_data/comments/*')).blank?
        @importables << EasyXmlData::CommentImportable.new(:xml => comments_xml)
      end
      unless (document_categories_xml = @xml.xpath('//easy_xml_data/document-categories/*')).blank?
        @importables << EasyXmlData::DocumentCategoryImportable.new(:xml => document_categories_xml)
      end
      unless (documents_xml = @xml.xpath('//easy_xml_data/documents/*')).blank?
        @importables << EasyXmlData::DocumentImportable.new(:xml => documents_xml)
      end
      unless (time_entry_activities_xml = @xml.xpath('//easy_xml_data/time-entry-activities/*')).blank?
        @importables << EasyXmlData::TimeEntryActivityImportable.new(:xml => time_entry_activities_xml)
      end
      unless (project_activities_xml = @xml.xpath('//easy_xml_data/project-activities/*')).blank?
        @importables << EasyXmlData::ProjectActivityImportable.new(:xml => project_activities_xml)
      end
      unless (project_activity_roles_xml = @xml.xpath('//easy_xml_data/project-activity-roles/*')).blank?
        @importables << EasyXmlData::ProjectActivityRoleImportable.new(:xml => project_activity_roles_xml)
      end
      unless (time_entries_xml = @xml.xpath('//easy_xml_data/time-entries/*')).blank?
        @importables << EasyXmlData::TimeEntryImportable.new(:xml => time_entries_xml)
      end
      unless (attachments_xml = @xml.xpath('//easy_xml_data/attachments/*')).blank?
        @importables << EasyXmlData::AttachmentImportable.new(:xml => attachments_xml)
      end
      unless (attachment_versions_xml = @xml.xpath('//easy_xml_data/attachment-versions/*')).blank?
        @importables << EasyXmlData::AttachmentVersionImportable.new(:xml => attachment_versions_xml)
      end
      unless (journals_xml = @xml.xpath('//easy_xml_data/journals/*')).blank?
        @importables << EasyXmlData::JournalImportable.new(:xml => journals_xml)
      end

      if defined?(EasyXmlData::EasyMoneySettingsImportable)
        unless (easy_money_setttings_xml = @xml.xpath('//easy_xml_data/easy-money-settings/*')).blank?
          @importables << EasyXmlData::EasyMoneySettingsImportable.new(:xml => easy_money_setttings_xml)
        end
      end

      if defined?(EasyXmlData::EasyMoneyOtherRevenueImportable)
        unless (easy_money_other_revenues_xml = @xml.xpath('//easy_xml_data/easy-money-other-revenues/*')).blank?
          @importables << EasyXmlData::EasyMoneyOtherRevenueImportable.new(:xml => easy_money_other_revenues_xml)
        end
      end

      if defined?(EasyXmlData::EasyMoneyOtherExpenseImportable)
        unless (easy_money_other_expenses_xml = @xml.xpath('//easy_xml_data/easy-money-other-expenses/*')).blank?
          @importables << EasyXmlData::EasyMoneyOtherExpenseImportable.new(:xml => easy_money_other_expenses_xml)
        end
      end

      if defined?(EasyXmlData::EasyMoneyExpectedRevenueImportable)
        unless (easy_money_expected_revenues_xml = @xml.xpath('//easy_xml_data/easy-money-expected-revenues/*')).blank?
          @importables << EasyXmlData::EasyMoneyExpectedRevenueImportable.new(:xml => easy_money_expected_revenues_xml)
        end
      end

      if defined?(EasyXmlData::EasyMoneyExpectedExpenseImportable)
        unless (easy_money_expected_expenses_xml = @xml.xpath('//easy_xml_data/easy-money-expected-expenses/*')).blank?
          @importables << EasyXmlData::EasyMoneyExpectedExpenseImportable.new(:xml => easy_money_expected_expenses_xml)
        end
      end

    end

  end
end

def ep(object, settings = 'g')
  seq = []
  settings.each_char do |c|
    case c
    when 'r'
      seq << '31'
    when 'g'
      seq << '32'
    when 'l'
      seq << '1'
    end
  end
  otpt = object.is_a?(String) ? object : object.pretty_inspect.strip
  puts "\033[#{seq.join(';')}m#{otpt}\033[0m"
  Rails.logger.warn otpt
end
