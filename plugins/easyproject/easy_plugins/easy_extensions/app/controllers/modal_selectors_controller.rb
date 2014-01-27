class ModalSelectorsController < ApplicationController

  before_filter :find_project

  helper :custom_fields
  include CustomFieldsHelper
  helper :entity_attribute
  include EntityAttributeHelper
  helper :easy_query
  include EasyQueryHelper
  helper :sort
  include SortHelper
  # Don't use ModalSelectorsHelper elsewhere!
  helper :modal_selectors
  include ModalSelectorsHelper
  helper :projects
  include ProjectsHelper

  def issue
    query = EasyIssueQuery.new(:name => (params[:query_name].blank? ? l('easy_query.easy_lookup.name.issue.default') : l("easy_query.easy_lookup.name.issue.#{params[:query_name]}")))
    query.display_filter_fullscreen_button = false
    qp = params.dup
    qp.delete(:project_id)
    qp.delete(:parent_selection)

    set_query(query, qp)

    query = EasyIssueQuery.new(:name => query.name) unless query.valid?

    if @project && params[:parent_selection]
      query.add_additional_statement("#{Issue.table_name}.project_id = #{@project.id}")
      query.project = @project
    elsif @project && !params[:parent_selection]
      if Setting.cross_project_issue_relations?
        query.add_short_filter('project_id', '=' + @project.id.to_s) if params[:operators].blank?
      else
        query.add_additional_statement("#{Issue.table_name}.project_id = #{@project.id}")
        query.project = @project
      end
    end

    sort_init(query.sort_criteria_init)
    sort_update(query.sortable_columns)

    entity_count = query.entity_count
    entity_pages = Redmine::Pagination::Paginator.new entity_count, default_per_page_rows, params['page']

    if entity_pages.last_page.to_i < params['page'].to_i
      render_404
      return false
    end

    entities = query.entities(:order => sort_clause, :offset => entity_pages.offset, :limit => default_per_page_rows)

    render_modal_selector_list(query, entities, entity_pages, entity_count)
  end

  def project
    query = EasyProjectQuery.new(:name => (params[:query_name].blank? ? l('easy_query.easy_lookup.name.project.default') : l("easy_query.easy_lookup.name.project.#{params[:query_name]}")))
    query.display_filter_fullscreen_button = false

    set_query(query)

    sort_init(query.sort_criteria_init)
    sort_update(query.sortable_columns)

    entities = query.entities(:order => "#{Project.table_name}.lft")
    render_modal_selector_tree(query, entities)
  end

  def version
    query = EasyVersionQuery.new(:name => (params[:query_name].blank? ? l('easy_query.easy_lookup.name.version.default') : l("easy_query.easy_lookup.name.version.#{params[:query_name]}")))
    query.display_filter_fullscreen_button = false

    set_query(query)

    sort_init(query.sort_criteria_init)
    sort_update(query.sortable_columns)

    entity_count = query.entity_count
    entity_pages = Redmine::Pagination::Paginator.new entity_count, default_per_page_rows, params['page']

    if entity_pages.last_page.to_i < params['page'].to_i
      render_404
      return false
    end

    entities = query.entities(:order => sort_clause, :offset => entity_pages.offset, :limit => default_per_page_rows)

    render_modal_selector_list(query, entities, entity_pages, entity_count)
  end

  def user
    query = EasyUserQuery.new(:name => (params[:query_name].blank? ? l('easy_query.easy_lookup.name.user.default') : l("easy_query.easy_lookup.name.user.#{params[:query_name]}")) )
    query.display_filter_fullscreen_button = false

    set_query(query)

    sort_init(query.sort_criteria_init)
    sort_update(query.sortable_columns)

    entity_count = query.entity_count
    entity_pages = Redmine::Pagination::Paginator.new entity_count, default_per_page_rows, params['page']

    if entity_pages.last_page.to_i < params['page'].to_i
      render_404
      return false
    end

    entities = query.entities(:order => sort_clause, :offset => entity_pages.offset, :limit => default_per_page_rows)

    render_modal_selector_list(query, entities, entity_pages, entity_count)
  end

  def group
    query = EasyGroupQuery.new(:name => (params[:query_name].blank? ? l('easy_query.easy_lookup.name.group.default') : l("easy_query.easy_lookup.name.group.#{params[:query_name]}")))
    query.display_filter_fullscreen_button = false

    set_query(query)

    sort_init(query.sort_criteria_init)
    sort_update(query.sortable_columns)

    entity_count = query.entity_count
    entity_pages = Redmine::Pagination::Paginator.new entity_count, default_per_page_rows, params['page']

    if entity_pages.last_page.to_i < params['page'].to_i
      render_404
      return false
    end

    entities = query.entities(:order => sort_clause, :offset => entity_pages.offset, :limit => default_per_page_rows)

    render_modal_selector_list(query, entities, entity_pages, entity_count)
  end

  def document
    query = EasyDocumentQuery.new(:name => (params[:query_name].blank? ? l('easy_query.easy_lookup.name.document.default') : l("easy_query.easy_lookup.name.document.#{params[:query_name]}")))
    query.display_filter_fullscreen_button = false
    query.display_filter_columns_on_index = true
    query.display_filter_group_by_on_index = true
    query.display_filter_sort_on_index = false

    set_query(query)

    sort_init(query.sort_criteria_init)
    sort_update(query.sortable_columns)

    entity_count = query.entity_count
    entity_pages = Redmine::Pagination::Paginator.new entity_count, default_per_page_rows, params['page']

    if entity_pages.last_page.to_i < params['page'].to_i
      render_404
      return false
    end

    entities = query.entities(:order => sort_clause, :offset => entity_pages.offset, :limit => default_per_page_rows)

    render_modal_selector_list(query, entities, entity_pages, entity_count)
  end

  def search

    @easy_query = params[:type].constantize.new(params[:easy_query]) if params[:type]
    @easy_query.name = params[:translated_query_name] || "_"
    @easy_query.display_filter_fullscreen_button = false
    @easy_query.display_filter_columns_on_index = false
    @easy_query.display_filter_group_by_on_index = false
    @easy_query.display_filter_sort_on_index = false

    params.delete(:project_id)
    set_query(@easy_query)
    @easy_query.project = nil

    sort_init(@easy_query.sort_criteria_init)
    sort_update(@easy_query.sortable_columns)

    @question = params[:easy_query_q] || ""
    @question.strip!

    if params[:modal_action] == 'issue' && @easy_query.is_a?(EasyIssueQuery)
      if @project && params[:parent_selection]
        @easy_query.add_additional_statement("#{Issue.table_name}.project_id = #{@project.id}")
        @easy_query.project = @project
      elsif @project && !params[:parent_selection]
        unless Setting.cross_project_issue_relations?
          @easy_query.add_additional_statement("#{Issue.table_name}.project_id = #{@project.id}")
          @easy_query.project = @project
        end
      end
    end

    hook_context = {:easy_query => @easy_query, :question => @question, :project => @project}
    call_hook(:controller_modal_selecotrs_action_search_before_search, hook_context)
    @question = hook_context[:question]
    @easy_query = hook_context[:easy_query]

    if @question.match(/^#?(\d+)$/)
      issues = Issue.visible.where(:id => $1)
      return render_modal_selector_list(@easy_query, Issue.visible.where(:id => $1), Redmine::Pagination::Paginator.new(issues.count, default_per_page_rows, params['page']), issues.count)
    end

    # extract tokens from the question
    # eg. hello "bye bye" => ["hello", "bye bye"]
    @tokens = @question.scan(%r{((\s|^)"[\s\w]+"(\s|$)|\S+)}).collect {|m| m.first.gsub(%r{(^\s*"\s*|\s*"\s*$)}, '')}
    # tokens must be at least 2 characters long
    @tokens = @tokens.uniq.select {|w| w.length > 1 }
    entity_count = @easy_query.search_freetext_count(@tokens)
    entity_pages = Redmine::Pagination::Paginator.new entity_count, default_per_page_rows, params['page']

    if entity_pages.last_page.to_i < params['page'].to_i
      render_404
      return false
    end

    if !@tokens.empty? && entity_count > 0
      # no more than 5 tokens to search for
      @tokens.slice! 5..-1 if @tokens.size > 5
      @entities = @easy_query.search_freetext(@tokens)
    elsif @question.blank?
      @entities = @easy_query.entities(:limit => default_per_page_rows, :offset => entity_pages.offset, :order => sort_clause)
    end

    render_modal_selector_list(@easy_query, @entities || [], entity_pages, entity_count)
  end

  private

  def find_project
    @project = Project.find(params[:project_id]) unless params[:project_id].blank?
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def render_modal_selector(query, entities, entity_pages = nil, entity_count = nil, selected_values = nil, easy_query_renderer_method = :render_modal_selector_easy_query_list, options = {})
    options[:button_selector_assign_label] ||= l(:button_easy_lookup_modal_selector_assign)
    options[:button_selector_assign_title] ||= l(:title_easy_lookup_modal_selector_assign)
    options[:button_close_label] ||= l(:button_easy_lookup_modal_close)
    options[:button_close_title] ||= l(:title_close)
    options[:multiple] = params[:multiple]
    options[:multiple] ||= '1'
    raise ArgumentError, 'Option selectable_entities has to be a Hash! {entity_name => field_name}' if options[:selectable_entities] && !options[:selectable_entities].is_a?(Hash)
    options[:selectable_entities] ||= {}

    render :partial => 'modal_selectors/modal_selector', :locals => { :query => query, :entities => entities, :entity_pages => entity_pages, :entity_count => entity_count, :selected_values => selected_values, :easy_query_renderer_method => easy_query_renderer_method, :options => options}
  end

  #kind of hack for call function 'format_html_entity_attribute'
  def link_to(*args, &block)
    view_context.link_to(*args, &block).html_safe
  end

  def mail_to(email_address, name = nil, html_options = {})
    view_context.mail_to(email_address, name, html_options)
  end

  def prepare_selected_values
    field_names = params['field_name'] && params['field_name'].gsub(/[\[\]]/,',').split(',').select{|x| !x.blank?}

    ids = params.value_at(field_names) if field_names

    return {} if ids.blank?
    ids = Array(ids)
    params.delete(field_names.first)

    if field_names.include?('custom_field_values')
      cf_id = field_names.last
      settings = CustomField.find(cf_id).settings
      entity_class = begin; settings['entity_type'].constantize rescue nil; end
      entity_attribute = settings['entity_attribute']
    else
      entity_class = begin; params[:action].classify.constantize rescue nil; end
      entity_attribute = params['entity_attribute']
    end

    if entity_class.nil? && params[:type] && params[:action] == 'search'
      query_type_class = begin; params[:type].classify.constantize rescue nil; end
      entity_class = begin; query_type_class.new.entity rescue nil; end
    end

    if entity_attribute.start_with?('link_with_')
      attribute = EasyEntityAttribute.new(entity_attribute.sub('link_with_', ''))
    else
      attribute = EasyEntityAttribute.new(entity_attribute, {:no_link => true})
    end

    selected_values = {}
    if entity_class && ids.any?
      entities = entity_class.where( :id => ids ).all
      ids.each do |id|
        next unless entity = entities.detect{|e| e.id == id.to_i }
        selected_values[id] = (format_html_entity_attribute(entity_class, entity_attribute, attribute.value(entity), {:entity => entity}) || '').to_str.html_safe
      end
    end
    selected_values
  end

  def render_modal_selector_list(query, entities, entity_pages, entity_count, options={})
    selected_values = prepare_selected_values

    render_modal_selector(query, entities, entity_pages, entity_count, selected_values, :render_modal_selector_easy_query_list, options)
  end

  def render_modal_selector_tree(query, entities, options={})
    selected_values = prepare_selected_values

    render_modal_selector(query, entities, nil, nil, selected_values, :render_modal_selector_easy_query_tree, options)
  end

  # entities looks like
  # ['project0', ['project1', ['category1', 'category2']], 'project2', ['project3', [['category4', ['story1', 'story2']]]]]
  # it means:
  # => project0 has no category
  # => project1 has two categories - category1 and category2
  # => project2 has no category
  # => project3 has one category4 with two stories - story1 and story2
  #
  # columns looks like
  # => [['name'], ['category_name'], ['story_name', 'autor']]
  # => but it is not array of names but it is array of EasyQueryColumns from EasyQuery
  def render_modal_selector_multi_tree(query, entities, columns, options={})
    selected_values = prepare_selected_values

    render_modal_selector(query, entities, nil, nil, selected_values, :render_modal_selector_easy_query_multi_tree, options.merge({:columns => columns}))
  end

  def set_query(query, query_params=nil)
    query_params ||= params
    query.from_params(query_params)
    query.export_formats = {}
  end

  def default_per_page_rows
    17
  end

end
