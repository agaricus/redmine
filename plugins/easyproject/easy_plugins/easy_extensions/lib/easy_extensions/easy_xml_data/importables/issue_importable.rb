require 'easy_extensions/easy_xml_data/importables/importable'
module EasyXmlData
  class IssueImportable < Importable
    
    def initialize(data)
      @klass = Issue
      super
    end
    
    def mappable?
      false
    end
    
    def update_attribute(record, name, value, map, xml)
      case name
      when 'project_id'
        record.project_id = map['project'][value.to_i]
      else
        super
      end
    end
    
  end
end