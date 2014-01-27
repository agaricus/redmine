require 'easy_extensions/easy_xml_data/importables/importable'
module EasyXmlData
  class UserImportable < Importable
    
    def initialize(data)
      @klass = User
      super
    end
    
    def mappable?
      true
    end
    
    private

    def update_attribute(record, name, value, map, xml)
      case name
      when 'easy_lesser_admin_permissions'
        record.easy_lesser_admin_permissions = value.blank? ? [] : value.to_a
      else
        super
      end
    end
    
    def existing_entities
      klass.all.sort_by(&:name)
    end
    
    def entities_for_mapping
      users = []
      @xml.xpath('//easy_xml_data/users/*').each do |user_xml|
        login = user_xml.xpath('login').text
        name = user_xml.xpath('firstname').text + ' ' + user_xml.xpath('lastname').text
        mail = user_xml.xpath('mail').text
        match = User.find(:first, :conditions => ['login = ? or mail = ?', login, mail])
        users << {:id => user_xml.xpath('id').text, :login => login, :name => name, :match => match ? match.id : ''}
      end
      users
    end
    
  end
end
