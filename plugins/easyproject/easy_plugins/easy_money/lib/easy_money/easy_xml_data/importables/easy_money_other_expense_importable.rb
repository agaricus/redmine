require 'easy_extensions/easy_xml_data/importables/importable'
module EasyXmlData
  class EasyMoneyOtherExpenseImportable < Importable
    
    def initialize(data)
      @klass = EasyMoneyOtherExpense
      super
    end
    
    def mappable?
      false
    end
    
  end
end