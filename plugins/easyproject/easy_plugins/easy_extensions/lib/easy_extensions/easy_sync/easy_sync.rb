class EasySync

  def initialize(options)
    @entity = options[:entity]
    @new_record_attributes = options[:new_record_attributes] || {}
    load_mappings
    load_data
  end

  def match_records
    records.each do |record|
      matching_item = find_matching_item(record)
      if matching_item
        create_relation(record, matching_item)
      end
    end
  end

  def sync(only_new = false)
    @items.each do |item|
      relation = EasySyncRelation.where(relation_attributes(item).merge({:entity_type => @entity.name})).first
      record = nil
      if relation == nil
        record = @entity.new(@new_record_attributes)
      elsif !only_new
        record = relation.entity
      end

      if record
        update_record(record, item)
        if relation == nil
          create_relation(record, item)
        end
      end
    end
    after_sync
  end

  private

  def load_mappings
    @mappings = EasySyncMapping.where(:category => self.class.name).all
  end

  def find_matching_item(record)
    matching_item = nil
    @items.each do |item|
      if match?(record, item)
        matching_item = item
        break
      end
    end
    matching_item
  end

  def update_record(record, item)
    @mappings.each do |mapping|
      update_record_attribute(record, item, mapping)
    end

    record.save!
  end

  def update_record_attribute(record, item, mapping)
    if mapping.local_name && record.respond_to?(mapping.local_name + '=')
      record.send(mapping.local_name + '=', item[mapping.id])
    end

    if mapping.local_id
      if record.new_record?
        record.save
      end
      custom_value = record.custom_value_for(mapping.local_id) || CustomValue.new({:customized_type => @entity.name, :customized_id => record.id, :custom_field_id => mapping.local_id})
      custom_value.value = item[mapping.id]
      custom_value.save
    end
  end

  def create_relation(record, item)
    ra = relation_attributes(item)
    unless record.sync_relations.find(:first, :conditions => ra)
      record.sync_relations.create(ra)
    end
  end

  def after_sync
  end

end
