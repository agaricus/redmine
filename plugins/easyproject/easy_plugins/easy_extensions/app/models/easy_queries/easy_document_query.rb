class EasyDocumentQuery < EasyQuery

  def self.permission_view_entities
    :view_documents
  end

  def self.filter_non_restricted_documents(documents, user, row_limit, sort_by)
    documents_count = 0

    documents = documents.inject(Hash.new{|hash,key| hash[key] = Array.new}) do |mem, var|
      if (row_limit == 0 || documents_count < row_limit) && allow_document?(var, user)
        group = case sort_by
          when 'date'
            var.updated_on.to_date
          when 'title'
            var.title.first.upcase
          when 'author'
            var.attachments.last && var.attachments.last.author || nil
          when 'project'
            var.project
          else
            var.category
        end
        mem[group] << var
        documents_count +=1
      end

      mem
    end

    return documents_count, documents
  end

  def query_after_initialize
    super
    self.sort_criteria = {'0'=>['project', 'asc'], '1' => ['',''], '2' => ['', '']} if self.sort_criteria.blank?
    self.display_filter_columns_on_index, self.display_filter_group_by_on_index, self.display_filter_sort_on_index = false, false, true
    self.display_filter_columns_on_edit, self.display_filter_group_by_on_edit, self.display_filter_sort_on_edit = false, false, true
    self.display_project_column_if_project_missing = false
    self.easy_query_entity_controller = 'easy_documents'
  end

  def filters_active?
    return self.filters != self.default_filter || self.list_columns_changed? || self.grouped? || self.sort_criteria != [['project', 'asc']]
  end

  def available_filters
    return @available_filters unless @available_filters.blank?

    @available_filters = {
      'category_id' => { :type => :list, :order => 1, :values => Proc.new{DocumentCategory.active.collect {|i| [i.name, i.id.to_s]}}, :groupable => true, :group => l("label_filter_group_#{self.class.name.underscore}")},
      'title' => {:type => :text, :order => 5, :group => l("label_filter_group_#{self.class.name.underscore}")},
      'description' => {:type => :text, :order => 10, :group => l("label_filter_group_#{self.class.name.underscore}")},
      'created_on' => {:type => :date_period, :order => 15, :time_column => true, :group => l("label_filter_group_#{self.class.name.underscore}")},
      'attachment_created_on' => {:type => :date_period, :order => 17, :time_column => true, :group => l("label_filter_group_#{self.class.name.underscore}")}
    }

    @available_filters['project_id'] = { :type => :list_optional, :order => 3, :values => Proc.new{self.projects_for_select}, :group => l("label_filter_group_#{self.class.name.underscore}")}
    add_custom_fields_filters(DocumentCategoryCustomField)

    @available_filters
  end

  def available_columns
    unless @available_columns_added
      @available_columns = [
        EasyQueryColumn.new(:title, :sortable => "#{Document.table_name}.title"),
        EasyQueryColumn.new(:category, :sortable => "#{DocumentCategory.table_name}.name", :groupable => true),
        EasyQueryColumn.new(:project, :sortable => "#{Project.table_name}.name", :groupable => true),
        EasyQueryColumn.new(:created_on, :sortable => "#{Document.table_name}.created_on")
      ]
      @available_columns_added = true
    end
    @available_columns
  end

  def default_list_columns
    @default_list_columns ||= ['category', 'project', 'title', 'created_on', 'attachments']
  end

  def list_columns_changed?
    return false
  end

  def default_find_include
    [:project, :category, :attachments]
  end

  def default_sort_criteria
    [['category', 'asc'], ['title', 'asc']]
  end

  def entity
    Document
  end

  def entity_scope
    Document.visible
  end

  protected

  def get_custom_sql_for_field(field, operator, value)
    if field == "attachment_created_on"
      db_table = Attachment.table_name
      db_field = 'created_on'
      return sql_for_field(field, operator, value, db_table, db_field)
    end
  end

  def self.allow_document?(doc, user)
    allow = true
    if doc.respond_to?(:active_record_restricted?)
      allow = !doc.active_record_restricted?(user, :read)
    end

    return allow
  end

end
