require 'easy_extensions/easy_xml_data/importables/importable'

module EasyXmlData
  class ProjectCustomFieldImportable < Importable
    
    def initialize(data)
      @klass = ProjectCustomField
      super
    end
    
    def mappable?
      true
    end
    
    private
    
    def entities_for_mapping
      project_custom_fields = []
      @xml.xpath('//easy_xml_data/project-custom-fields/*').each do |project_custom_field_xml|
        internal_name = project_custom_field_xml.xpath('internal-name').try(:text)
        name = project_custom_field_xml.xpath('name').try(:text)
        unless internal_name.blank?
          match = ProjectCustomField.find(:first, :conditions => {:internal_name => internal_name})
        end
        if match.blank?
          match = ProjectCustomField.find(:first, :conditions => {:name => name})
        end
        project_custom_fields << {:id => project_custom_field_xml.xpath('id').text, :name => name, :match => match ? match.id : ''}
      end
      project_custom_fields
    end
    
  end
end