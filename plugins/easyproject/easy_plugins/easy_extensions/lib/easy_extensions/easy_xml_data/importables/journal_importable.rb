require 'easy_extensions/easy_xml_data/importables/importable'
module EasyXmlData
  class JournalImportable < Importable
    
    def initialize(data)
      @klass = Journal
      super
    end
    
    def mappable?
      false
    end
    
    private
    
    def update_detail_from_map(detail, identifier, map)
      ep "identifier: #{identifier}"
      unless detail.old_value.blank?
        if map[identifier][detail.old_value.to_i]
          detail.old_value = map[identifier][detail.old_value.to_i]
        else
          ep "old value (#{detail.old_value}) not in map['#{identifier}']"
        end
      end
      unless detail.value.blank?
        if map[identifier][detail.value.to_i]
          detail.value = map[identifier][detail.value.to_i]
        else
          ep "value (#{detail.value}) not in map['#{identifier}']"
        end
      end
    end
    
    def update_attribute(journal, name, value, map, xml)
      if name == 'details'
        journal.details = []
        xml.xpath('detail').each do |detail_xml|
          detail = JournalDetail.new
          detail.property = detail_xml.xpath('property').text
          pk = detail_xml.xpath('prop-key').text
          old_value_xml = detail_xml.xpath('old-value')
          detail.old_value = old_value_xml.text unless old_value_xml.first['nil']
          value_xml = detail_xml.xpath('value')
          detail.value = value_xml.text unless value_xml.first['nil']
          case detail.property
          when 'attachment'
            detail.prop_key = map['attachment'][pk.to_i] || map['attachment/version'][pk.to_i]
          when 'attr'
            detail.prop_key = pk
            ep "attr #{pk}"
            case pk
            when 'assigned_to_id'
              update_detail_from_map(detail, 'user', map)
            when 'status_id'
              update_detail_from_map(detail, 'issue_status', map)
            when 'priority_id'
              update_detail_from_map(detail, 'issue_priority', map)
            end
          else
            detail.prop_key = pk
          end
          if !detail.prop_key.blank? && detail.save
            journal.details << detail
          end
        end
      else
        super
      end
    end
    
  end
end