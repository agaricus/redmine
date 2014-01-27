require 'easy_extensions/easy_xml_data/importables/importable'
module EasyXmlData
  class TimeEntryImportable < Importable
    
    def initialize(data)
      @klass = TimeEntry
      super
    end
    
    def mappable?
      false
    end
    
  end
end