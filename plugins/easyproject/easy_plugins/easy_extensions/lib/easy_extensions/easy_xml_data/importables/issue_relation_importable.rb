require 'easy_extensions/easy_xml_data/importables/importable'
module EasyXmlData
  class IssueRelationImportable < Importable
    
    def initialize(data)
      @klass = IssueRelation
      super
    end
    
    def mappable?
      false
    end
    
    private
    
    
    
  end
end