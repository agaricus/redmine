require 'easy_extensions/easy_sync/easy_sync'
require 'odbc_utf8'

class EasySyncOdbc < EasySync
  
  def initialize(options)
    @dsn = options[:dsn]
    @query = options[:query]
    super
  end
  
  def connect
    @db = ODBC::connect @dsn
    return @db && @db.connected?
  end
  
  def load_data
    @raw_data = []
    if connect
      statement = @db.run @query
      while row = statement.fetch
        @raw_data << row
      end
      process_data
    end
  end
  
  def process_data
    @items = []
    @raw_data.each do |raw_item|
      item = {}
      @mappings.each do |mapping|
        v = get_attribute_value(mapping, raw_item)
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
              v = v.to_s.to_date
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
  
  def get_attribute_value(mapping, raw_item)
    raw_item[mapping.remote_id]
  end
  
  def after_sync
    if @db
      @db.drop_all
    end
  end
    
end
