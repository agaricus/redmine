class EasyGroupQuery < EasyQuery

  def available_filters
    return @available_filters unless @available_filters.blank?
    @available_filters = {
      'lastname' => { :type => :text, :order => 1, :group => l("label_filter_group_#{self.class.name.underscore}") },
      'created_on' => { :type => :date_period, :order => 2, :group => l("label_filter_group_#{self.class.name.underscore}")},
      'updated_on' => { :type => :date_period, :order => 3, :group => l("label_filter_group_#{self.class.name.underscore}")}
    }
    add_custom_fields_filters(GroupCustomField)

    @available_filters
  end

  def available_columns
    unless @available_columns_added
      @available_columns = [
        EasyQueryColumn.new(:lastname, :sortable => "#{Group.table_name}.lastname", :groupable => true),
        EasyQueryColumn.new(:created_on, :sortable => "#{Group.table_name}.created_on", :groupable => true),
        EasyQueryColumn.new(:updated_on, :sortable => "#{Group.table_name}.updated_on", :groupable => true)
      ]
      @available_columns += GroupCustomField.all.collect {|cf| EasyQueryCustomFieldColumn.new(cf)}
      @available_columns_added = true
    end
    @available_columns
  end

  def default_list_columns
    @default_list_columns ||= ['lastname', 'created_on']
  end

  def default_sort_criteria
    [['lastname', 'asc']]
  end

  def entity
    Group
  end

end
