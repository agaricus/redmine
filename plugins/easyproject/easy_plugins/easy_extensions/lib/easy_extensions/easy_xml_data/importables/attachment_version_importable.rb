require 'easy_extensions/easy_xml_data/importables/importable'
module EasyXmlData
  class AttachmentVersionImportable < Importable
    
    def initialize(data)
      @klass = Attachment::Version
      super
      @belongs_to_associations['attachment_id'] = 'attachment'
    end
    
    def mappable?
      false
    end
    
  end
end