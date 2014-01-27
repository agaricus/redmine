class EpmDocuments < EasyPageModule

  def category_name
    @category_name ||= 'others'
  end

  def permissions
    @permissions ||= [:view_documents]
  end

  def get_show_data(settings, user, page_context = {})
    row_limit = settings['row_limit'].to_i

    if settings['query_type'] == '2'
      query = EasyDocumentQuery.new(:name => settings['query_name'])
      query.from_params(settings)
      query.additional_statement =  Project.allowed_to_condition(user, :view_documents)
      documents = query.entities({:include => [:project, :category, {:attachments => :versions}]})

      documents_count, documents = EasyDocumentQuery.filter_non_restricted_documents(documents, user, row_limit, settings['sort_by'])
    elsif !settings['query_id'].blank?
      query = EasyDocumentQuery.find(settings['query_id'])
      query.additional_statement =  Project.allowed_to_condition(user, :view_documents)
      documents = query.entities({:include => [:project, :category, {:attachments => :versions}]})

      documents_count, documents = EasyDocumentQuery.filter_non_restricted_documents(documents, user, row_limit, settings['sort_by'])
    else
      documents = Document.find(:all,
        :order => "#{Document.table_name}.created_on DESC",
        :conditions => Project.allowed_to_condition(user, :view_documents),
        :include => [:project, :category, {:attachments => :versions}])

      if row_limit > 0
        documents = documents.first(row_limit)
      end

      documents_count = documents.count

      case settings['sort_by']
      when 'date'
        documents = documents.group_by {|d| d.updated_on.to_date }
      when 'title'
        documents = documents.group_by {|d| d.title.first.upcase}
      when 'author'
        documents = documents.select{|d| d.attachments.any?}.group_by {|d| d.attachments.last.author}
      when 'project'
        documents = documents.select{|d| d.attachments.any?}.group_by {|d| d.project}
      else
        documents = documents.group_by(&:category)
      end
    end

    return {:documents => documents, :documents_count => documents_count}
  end

  def get_edit_data(settings, user, page_context = {})
    query = EasyDocumentQuery.new(:name => (settings['query_name'] || '_'))
    query.additional_statement =  Project.allowed_to_condition(user, :view_documents)
    query.display_filter_fullscreen_button = false
    query.export_formats = {}
    query.from_params(settings) if settings['query_type'] == '2'

    return {:query => query}
  end

end