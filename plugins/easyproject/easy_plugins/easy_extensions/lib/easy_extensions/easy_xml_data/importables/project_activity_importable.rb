require 'easy_extensions/easy_xml_data/importables/importable'
module EasyXmlData
  class ProjectActivityImportable < Importable
    
    def initialize(data)
      @klass = ProjectActivity
      super
    end
    
    def mappable?
      false
    end
    
    private
    
    def import_record(xml, map)
      ep "importing #{klass.name}#N/A"
      record = create_record(xml, map)
      if record.blank? || record.new_record?
        ep 'import failed'
      else
        ep "imported as #{record.class.name}#N/A"
      end
    end
    
    def before_record_save(record, xml, map)
      ProjectActivity.find(:first, :conditions => {:project_id => record.project_id, :activity_id => record.activity_id}).blank?      
    end
    
  end
end