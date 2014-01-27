require 'easy_extensions/easy_xml_data/importables/importable'
module EasyXmlData
  class NewsImportable < Importable
    
    def initialize(data)
      @klass = News
      super
    end
    
    def mappable?
      false
    end
    
    private
    
    def updatable_attribute?(name)
      name != 'comments_count' && super(name)
    end
    
  end
end