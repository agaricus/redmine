require 'easy_extensions/easy_xml_data/importables/importable'
module EasyXmlData
  class IssueStatusImportable < Importable

    def initialize(data)
      @klass = IssueStatus
      super
    end
    
    def mappable?
      true
    end
    
    private
    
    def entities_for_mapping
      statuses = []
      @xml.xpath('//easy_xml_data/issue-statuses/*').each do |status_xml|
        name = status_xml.xpath('name').text
        match = IssueStatus.find(:first, :conditions => {:name => name})
        statuses << {:id => status_xml.xpath('id').text, :name => name, :match => match ? match.id : ''}
      end
      statuses
    end
    
  end
end