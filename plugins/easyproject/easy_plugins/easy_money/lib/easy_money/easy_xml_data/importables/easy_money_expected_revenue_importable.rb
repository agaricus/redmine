require 'easy_extensions/easy_xml_data/importables/importable'
module EasyXmlData
  class EasyMoneyExpectedRevenueImportable < Importable
    
    def initialize(data)
      @klass = EasyMoneyExpectedRevenue
      super
    end
    
    def mappable?
      false
    end
      
  end
end