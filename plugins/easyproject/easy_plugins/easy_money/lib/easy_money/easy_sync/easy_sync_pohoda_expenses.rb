require 'easy_extensions/easy_sync/easy_sync_odbc'
require 'easy_money/easy_sync/easy_sync_pohoda_tools'
class EasySyncPohodaExpenses < EasySyncOdbc
    
    def initialize(options)
      @pohoda_id_mapping = EasySyncMapping.find(:first, :conditions => {:category => self.class.name, :local_name => 'pohoda_id'})
      @name_mapping = EasySyncMapping.find(:first, :conditions => {:category => self.class.name, :local_name => 'name'})
      super({:entity => EasyMoneyOtherExpense,
             :query => EasySyncPohodaTools.query(options[:pohoda_id] || options[:entity_id], false),
             :dsn => options[:dsn],
             :new_record_attributes => {:entity_type => 'Project', :entity_id => options[:entity_id]}
            })
    end
    
    private
    
    def match?(revenue, item)
      sm = revenue.sync_relations.find(:first, :conditions => relation_attributes(item))
      sm != nil
    end
    
    def relation_attributes(item)
      {:direction => 'import', :remote_name => 'pohoda', :remote_id => item[@pohoda_id_mapping.id]}
    end
    
    def update_record_attribute(record, item, mapping)
      if mapping.local_name == @name_mapping.local_name
        record.name = item[@name_mapping.id].blank? ? '-' : item[@name_mapping.id]
      else
        super
      end
    end
end