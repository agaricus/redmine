require 'easy_extensions/easy_xml_data/importables/importable'

module EasyXmlData
  class IssueCustomFieldImportable < Importable
    
    def initialize(data)
      @klass = IssueCustomField
      super
    end
    
    def mappable?
      true
    end
    
    private

    def update_attribute(record, name, value, map, xml)
      case name
      when 'settings'
        settings = {}
        xml.children.select{|c| !c.text?}.map{|c| settings[c.name.underscore] = c.text}
      else
        super
      end
    end
    
    def entities_for_mapping
      issue_custom_fields = []
      @xml.xpath('//easy_xml_data/issue-custom-fields/*').each do |issue_custom_field_xml|
        internal_name = issue_custom_field_xml.xpath('internal-name').text
        name = issue_custom_field_xml.xpath('name').text
        match = nil
        unless internal_name.blank?
          match = IssueCustomField.find(:first, :conditions => {:internal_name => internal_name})
        end
        if match.blank?
          match = IssueCustomField.find(:first, :conditions => {:name => name})
        end
        issue_custom_fields << {:id => issue_custom_field_xml.xpath('id').text, :name => name, :match => match ? match.id : ''}
      end
      issue_custom_fields
    end
    
  end
end
