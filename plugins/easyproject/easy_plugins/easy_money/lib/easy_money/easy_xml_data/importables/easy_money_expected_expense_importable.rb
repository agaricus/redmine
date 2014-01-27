require 'easy_extensions/easy_xml_data/importables/importable'
module EasyXmlData
  class EasyMoneyExpectedExpenseImportable < Importable
    
    def initialize(data)
      @klass = EasyMoneyExpectedExpense
      super
    end
    
    def mappable?
      false
    end
    
  end  
end