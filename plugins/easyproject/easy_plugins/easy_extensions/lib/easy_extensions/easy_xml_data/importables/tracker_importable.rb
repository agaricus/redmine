require 'easy_extensions/easy_xml_data/importables/importable'
module EasyXmlData
  class TrackerImportable < Importable
    
    def initialize(data)
      @klass = Tracker
      super
    end
    
    def mappable?
      true
    end
    
    private
    
    def updatable_attribute?(name)
      super(name) && name != 'position'
    end
    
    def get_belongs_to_many_attribute(record, name, value, map, xml)
      ep "name: #{name}, value: #{value}"
      if map.has_key?(@belongs_to_many_associations[name])
        value = []
        type = @belongs_to_many_associations[name]
        xml.children.each do |other_xml|
          other_id = other_xml.text.to_i
          if other_id && map[type][other_id]
            value << map[type][other_id]
          end
        end
        type = 'custom_field' if type == 'issue_custom_field'
        ep "name: #{"#{type}_ids"}, value: #{value}"
        ["#{type}_ids", value]
      else
        [nil, nil]
      end
    end
    
    def entities_for_mapping
      trackers = []
      @xml.xpath('//easy_xml_data/trackers/*').each do |tracker_xml|
        name = tracker_xml.xpath('name').text
        match = Tracker.find(:first, :conditions => {:name => name})
        trackers << {:id => tracker_xml.xpath('id').text, :name => name, :match => match ? match.id : ''}
      end
      trackers
    end

  end
end
