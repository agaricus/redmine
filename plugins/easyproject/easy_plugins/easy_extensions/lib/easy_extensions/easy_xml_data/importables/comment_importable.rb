require 'easy_extensions/easy_xml_data/importables/importable'
module EasyXmlData
  class CommentImportable < Importable
    
    def initialize(data)
      @klass = Comment
      super
    end
    
    def mappable?
      false
    end
    
  end
end