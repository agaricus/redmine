require 'easy_extensions/easy_xml_data/importables/importable'
module EasyXmlData
  class AttachmentImportable < Importable
  
    def initialize(data)
      @klass = Attachment
      super
    end
    
    def mappable?
      false
    end
    
    def create_record(xml, map)
      attachment = super
      attachment.versions.each(&:delete)
      attachment.update_column(:version, xml.xpath('version').text)
      attachment.update_column(:disk_filename, xml.xpath('disk-filename').text)
      attachment
    end
  
  end
end