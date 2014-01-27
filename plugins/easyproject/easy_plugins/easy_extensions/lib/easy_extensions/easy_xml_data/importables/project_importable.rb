require 'easy_extensions/easy_xml_data/importables/importable'
module EasyXmlData
  class ProjectImportable < Importable
    
    def mappable?
      false
    end
    
    def initialize(data)
      @klass = Project
      super
    end
    
    private
    
    def update_attribute(project, name, value, map, xml)
      case name
      when 'enabled_modules'
        update_enabled_modules(project, xml)
      else
        super
      end
    end
    
    def after_record_save(project, xml, map)
      # project parent can only be set on a saved project
      parent_id = xml.xpath('parent-id').text
      if parent_id
        parent_id = parent_id.to_i
        if map['project'][parent_id]
          project.set_allowed_parent!(map['project'][parent_id])
        end
      end
    end

    def update_enabled_modules(project, xml)
      modules = []
      xml.xpath('enabled-module/name').each do |module_xml|
        modules << module_xml.text
      end
      project.enabled_module_names = modules
    end
    
    
    
  end
end