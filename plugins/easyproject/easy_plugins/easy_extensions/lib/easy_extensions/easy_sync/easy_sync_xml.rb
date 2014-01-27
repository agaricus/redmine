require 'easy_extensions/easy_sync/easy_sync'
require 'net/http'
require 'nokogiri'
class EasySyncXml < EasySync

  def initialize(options)
    @uri = URI(options[:url])
    @auth = options[:auth]
    @ssl = options[:ssl]
    @items_xpath = options[:items_xpath]
    @xml_items = []
    @items = []
    super
  end
  
  private

  def load_data
    http_options = {}
    if @auth
      http_options[:basic_user] = @auth[:username]
      http_options[:basic_password] = @auth[:password]
    end

    response = EasyUtils::HttpUtils.get_request(@uri, nil, http_options)
    @xml_items = Nokogiri::XML(response.body).xpath(@items_xpath)

    process_data
  end

  def process_data
    @items = []
    @xml_items.each do |xml_item|
      item = {}
      @mappings.each do |mapping|
        v = get_attribute_value(mapping, xml_item)
        if v
          begin
            case mapping.value_type
            when 'int'
              v = v.to_i
            when 'string'
              v = v.to_s
            when 'decimal'
              v = v.to_d
            when 'date'
              v = v.to_date
            end
          rescue Exception
            v = nil
          end
        end
        item[mapping.id] = v
      end
      @items << item
    end
  end

  def get_attribute_value(mapping, xml_item)
    xml_item.xpath(mapping.remote_name).text
  end

end