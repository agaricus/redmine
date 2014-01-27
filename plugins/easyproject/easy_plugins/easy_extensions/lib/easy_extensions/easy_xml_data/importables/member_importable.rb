require 'easy_extensions/easy_xml_data/importables/importable'
module EasyXmlData
  class MemberImportable < Importable
    
    def initialize(data)
      @klass = Member
      super
      @belongs_to_many_associations['roles'] = 'role'
    end
    
    def mappable?
      false
    end
    
  end
end