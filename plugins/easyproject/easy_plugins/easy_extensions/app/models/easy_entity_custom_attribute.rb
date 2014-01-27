class EasyEntityCustomAttribute < EasyEntityAttribute

  attr_reader :custom_field, :assoc

  def initialize(custom_field, options={})
    super("cf_#{custom_field.id}".to_sym, options)
    @custom_field = custom_field
    @assoc = options[:assoc]
  end

  def caption(with_suffixes=false)
    @custom_field.translated_name
  end

  def value(entity)
    entity = entity.send(assoc) if assoc

    if (entity.respond_to?(:project) && @custom_field.visible_by?(entity.project, User.current)) || !entity.respond_to?(:project)
      cv = entity.custom_values.select {|v| v.custom_field_id == @custom_field.id}.collect {|v| @custom_field.cast_value(v.value)}
      cv.size > 1 ? cv.sort {|a,b| a.to_s <=> b.to_s} : cv.first
    else
      nil
    end
  end

  def custom_value_of(entity)
    entity = entity.send(assoc) if assoc
    cv = entity.custom_value_for(custom_field)
  end

  def css_classes
    @css_classes ||= "#{name.to_s.underscore} #{@custom_field.field_format.to_s.underscore}"
  end

end

module EasyEntityCustomAttributeColumnExtensions

  def self.included(base)
    base.send(:include, EasySumableAttributeColumnExtension)
    base.send(:include, InstanceMethods)
  end

  attr_accessor :sortable, :groupable, :default_order

  def initialize(custom_field, options={})
    super(custom_field, options)
    self.sortable = custom_field.order_statement || nil
    self.groupable = custom_field.group_statement || false
    @inline = true
    if custom_field.summable?
      self.sumable ||= :both
      self.sumable_sql ||= custom_field.summable_sql
    end
  end

  def sortable?
    !sortable.nil?
  end

  module InstanceMethods
    def additional_joins(entity_class, type=:sql)
      result = super(entity_class, type)

      case type
      when :sql
        association = entity_class.reflect_on_all_associations(:belongs_to).detect{|as| as.name == assoc}
        result << "INNER JOIN #{association.klass.table_name} ON #{association.klass.table_name}.id = #{entity_class.table_name}.#{association.foreign_key}" if association
      when :array
        result << assoc
      end if assoc

      join_statement = custom_field.join_for_order_statement

      result << join_statement if join_statement

      result
    end
  end
end