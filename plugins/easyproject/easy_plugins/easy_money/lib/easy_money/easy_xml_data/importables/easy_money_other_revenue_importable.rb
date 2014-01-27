require 'easy_extensions/easy_xml_data/importables/importable'
module EasyXmlData
  class EasyMoneyOtherRevenueImportable < Importable
    
    def initialize(data)
      @klass = EasyMoneyOtherRevenue
      super
    end
    
    def mappable?
      false
    end
    
  end
end