module EasyXmlData
  class Importable
    
    def initialize(data)
      @xml = data[:xml]
      @belongs_to_associations, @belongs_to_polymorphic_associations = {}, {}
      klass.reflect_on_all_associations(:belongs_to).each do |association|
        if association.options[:polymorphic]
          @belongs_to_polymorphic_associations[association.name.to_s + '_id'] = association.options[:foreign_type] || association.foreign_type
        else
          @belongs_to_associations[association.name.to_s + "_id"] = association_id(association)
        end
      end
      @belongs_to_many_associations = {}
      klass.reflect_on_all_associations(:has_and_belongs_to_many).each do |association|
        @belongs_to_many_associations[association.name.to_s] = association_id(association)
      end
      @mapped = false if mappable?
      @validation_errors = []
    end

    attr_reader :klass
    attr_writer :mapped
    
    def import(map)
      ep "importing #{id.humanize.pluralize}...", 'r'
      map[id] ||= {}
      @xml.each do |record_xml|
        import_record(record_xml, map)
      end
      ep "current map:"
      ep map
      ep 'done', 'r'
      @validation_errors
    end
    
    def id
      klass.name.underscore
    end
    
    def mappable? 
      false
    end
    
    def mapped?
      mappable? && (@mapped || @xml.blank?)
    end
    
    def mapping_data
      return id, entities_for_mapping, existing_entities
    end
    
    private
    
    def import_record(xml, map)
      from_id = xml.xpath('id').text.to_i
      if map[self.id][from_id].blank?
        ep "importing #{klass.name}##{from_id}"
        record = create_record(xml, map)
        if record.blank? || record.new_record?
          ep 'import failed'
        else
          ep "imported as #{record.class.name}##{record.id}"
          map[self.id][from_id] = record.id
        end
      end
    end
    
    def create_record(xml, map)
      record = klass.new
      @belongs_to_polymorphic_associations.each do |name, foreign_type|
        type_xml = xml.xpath(foreign_type.dasherize)
        @belongs_to_associations[name] = type_xml.text.underscore
      end
      xml.children.each do |attr_xml|
        attr_name = attr_xml.name.underscore
        if updatable_attribute?(attr_name)
          attr_value = attr_xml.text
          update_attribute(record, attr_name, attr_value, map, attr_xml)
        end
      end
      
      if !defined?(before_record_save) || before_record_save(record, xml, map)
        unless record.save(:validate => !record.is_a?(Issue))
          error_message = "#{record.class.name} #{record.to_s}: "
          error_message << record.errors.full_messages.join(', ')
          ep "validation errors: #{error_message}", 'rl'
          @validation_errors << error_message
        end
        after_record_save(record, xml, map) if defined? after_record_save
        return record
      end
    end
    
    def update_attribute(record, name, value, map, xml)
      if name == 'custom_values'
        set_custom_values(record, map, xml)
        return
      elsif @belongs_to_associations.has_key?(name)
        name, value = get_belongs_to_attribute(record, name, value, map, xml)
      elsif @belongs_to_many_associations.has_key?(name)
        name, value = get_belongs_to_many_attribute(record, name, value, map, xml)
      end
      if xml['type'] == 'yaml'
        if xml['nil'] == 'true'
          value = nil
        else
          value = YAML::load(value)
        end
      elsif xml['type'] == 'array'
        value = value.blank? ? [] : value.to_a
      end
      record.send("#{name}=", value) if !name.blank? && record.respond_to?("#{name}=")
    end
    
    def set_custom_values(record, map, xml)
      values = {}
      xml.xpath('./*').each do |custom_value_xml|
        next if custom_value_xml.text?
        custom_field_id = custom_value_xml.xpath('custom-field-id').text.to_i
        value = custom_value_xml.xpath('value').text
        imported_custom_field_id = map["#{id}_custom_field"][custom_field_id]
        values[imported_custom_field_id] = value unless imported_custom_field_id.blank?
      end
      record.custom_field_values = values
    end
    
    def get_belongs_to_attribute(record, name, value, map, xml)
      if map.has_key?(@belongs_to_associations[name])
        n, v = [name, map[@belongs_to_associations[name]][value.to_i]]
        [n, v]
      else
        [name, nil]
      end
    end
    
    def get_belongs_to_many_attribute(record, name, value, map, xml)
      if map.has_key?(@belongs_to_many_associations[name])
        value = []
        type = @belongs_to_many_associations[name]
        xml.children.each do |other_xml|
          other_id = other_xml.text.to_i
          if other_id && map[type][other_id]
            value << map[type][other_id]
          end
        end
        ["#{type}_ids", value]
      else
        [nil, nil]
      end
    end
    
    def updatable_attribute?(attr_name)
      !['id', 'lft', 'rgt', 'parent_id'].include?(attr_name)
    end
    
    def entities_for_mapping
      raise StandardError, 'this method should be overriden'
    end
    
    def existing_entities
      klass.all
    end
    
    def association_id(association)
      cn = association.class_name.underscore
      cn == 'principal' ? 'user' : cn
    end
    
  end
end
