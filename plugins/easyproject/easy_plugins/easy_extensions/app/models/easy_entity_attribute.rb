class EasyEntityAttribute
  include Redmine::I18n

  attr_accessor :name, :no_link, :includes

  def initialize(name, options={})
    self.name = name.to_sym
    @caption_key = options[:caption] || "field_#{name}"
    @no_link = options[:no_link].nil? ? false : options[:no_link]
    @inline = options.key?(:inline) ? options[:inline] : true
    @includes = options[:includes]
  end

  def caption(with_suffixes=false)
    l(@caption_key)
  end

  def inline?
    @inline
  end

  def value(entity)
    entity.nested_send(name)
  end

  def css_classes
    name.to_s.underscore
  end

end

module EasyEntityAttributeColumnExtensions

  def self.included(base)
    base.send(:include, EasySumableAttributeColumnExtension)
  end

  # sumable => :top || :bottom || :both
  attr_accessor :sortable, :groupable, :default_order

  def initialize(name, options={})
    super(name, options)
    self.sortable = options[:sortable].is_a?(Proc) ? options[:sortable].call : options[:sortable]
    self.groupable = options[:groupable] || false
    if groupable == true
      if self.sortable.is_a?(String)
        self.groupable = self.sortable
      else
        self.groupable = name.to_s
      end
    end
    self.default_order = options[:default_order]
  end

  def sortable?
    !sortable.nil?
  end

end

module EasySumableAttributeColumnExtension
#it is aweful, but cuz EntityAttributeExtensions and EntityAttributeCustomExtensions... (WHY???) it is best way
  class EasySumableOptions

    def initialize(*args)
      raise ArgumentError, 'Sumable Options has to be build from hash' unless args.first.is_a?(Hash)
      @distinct_columns_count = 0
      parse_options(args.shift)
    end

    def parse_options(options={})
      @distinct_columns = {:sql => [], :call => []}
      @distinct_columns_count = 0


      distinct_columns = options.delete(:distinct_columns)
      return unless distinct_columns

      has_count = @distinct_columns.keys.count
      distinct_columns.each do |dc|
        if dc.is_a?(Array)
          raise ArgumentError, 'Distinct column array has to have '+has_count.to_s+' members and has '+dc.count.to_s unless dc.count == has_count
          @distinct_columns[:sql] << dc.first
          @distinct_columns[:call] << dc.second
        elsif dc.is_a?(String)
          @distinct_columns[:sql] << dc
          @distinct_columns[:call] << dc.split(',').last.to_sym
        elsif dc.is_a?(Symbol)
          @distinct_columns[:sql] << dc.to_s
          @distinct_columns[:call] << dc
        end
        @distinct_columns_count += 1
      end
    end

    # type for columns ( :sql = string to sql query, :call = callable for the entity of query)
    def distinct_columns(type = :sql)
      @distinct_columns[type]
    end

    def distinct_columns?
      @distinct_columns_count > 0
    end

  end #end class SumableOptions

  attr_accessor :sumable, :sumable_sql, :polymorphic

  attr_reader :sumable_options

  def initialize(name, options={})
    @sumable_header = !options[:disable_header_sum]
    self.sumable = options[:sumable]
    self.sumable_sql = options[:sumable_sql]
    self.sumable_options = options[:sumable_options] || {}
    self.polymorphic = options[:polymorphic]
    super(name, options)
  end

  def caption(with_suffixes = false)
    super + (with_suffixes && sumable_header? ? ' (SUM)' : '')
  end

  def sumable_options=(options)
    @sumable_options = EasySumableOptions.new(options, name)
  end

  def sumable?
    !sumable.nil?
  end

  def sumable_header?
    self.sumable? && @sumable_header
  end

  def sumable_top?
    return self.sumable? && (self.sumable == :top || self.sumable == :both)
  end

  def sumable_bottom?
    return self.sumable? && (self.sumable == :bottom || self.sumable == :both)
  end

  def sumable_both?
    return self.sumable? && self.sumable == :both
  end

  def polymorphic?
    !self.polymorphic.nil?
  end

  def additional_joins(entity_class, type=:sql)
    []
  end

end
