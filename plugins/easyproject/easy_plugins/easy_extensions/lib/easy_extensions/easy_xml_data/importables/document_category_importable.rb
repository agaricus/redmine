require 'easy_extensions/easy_xml_data/importables/importable'
module EasyXmlData
  class DocumentCategoryImportable < Importable
    
    def initialize(data)
      @klass = DocumentCategory
      super
    end
    
    def mappable?
      true
    end
    
    def entities_for_mapping
      document_categories = []
      @xml.xpath('//easy_xml_data/document-categories/*').each do |document_category_xml|
        name = document_category_xml.xpath('name').text
        match = DocumentCategory.find(:first, :conditions => {:name => name})
        document_categories << {:id => document_category_xml.xpath('id').text, :name => name, :match => match ? match.id : ''}
      end
      document_categories
    end
    
  end
end