require 'easy_extensions/easy_xml_data/importables/importable'
module EasyXmlData
  class VersionImportable < Importable
    
    def initialize(data)
      @klass = Version
      super
    end
    
    def mappable?
      false
    end
    
  end
end