require 'easy_extensions/easy_xml_data/importables/importable'
module EasyXmlData
  class DocumentImportable < Importable
    
    def initialize(data)
      @klass = Document
      super
    end
    
    def mappable?
      false
    end
    
  end
end