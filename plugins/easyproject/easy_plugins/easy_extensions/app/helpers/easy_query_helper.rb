module EasyQueryHelper
  include Redmine::Export::PDF

  # -----------------------------------------
  # retrieve query for entity - EasyIssueQuery, EasyUserQuery ...
  def retrieve_query(entity_query, options={})
    entity_session = entity_query.name.underscore
    if !params[:query_id].blank?
      cond = 'project_id IS NULL'
      cond << " OR project_id = #{@project.id}" if @project
      @query = entity_query.where(cond).find(params[:query_id])
      raise ::Unauthorized unless @query.visible?
      @query.project = @project
      session[entity_session] = {:id => @query.id, :project_id => @query.project_id}
      sort_clear
    elsif params[:set_filter] || session[entity_session].nil? || session[entity_session][:project_id] != (@project ? @project.id : nil)
      # Give it a name, required to be valid
      @query = entity_query.new(:name => "_", :project => @project)
      @query.from_params(options[:query_param] ? params[options[:query_param]] : params)
      session[entity_session] = {:project_id => @query.project_id, :filters => @query.filters, :group_by => @query.group_by, :column_names => @query.column_names}
    else
      @query = nil
      @query = entity_query.find(session[entity_session][:id]) if session[entity_session][:id] && entity_query.exists?(session[entity_session][:id])
      @query ||= entity_query.new(:name => "_", :filters => session[entity_session][:filters], :group_by => session[entity_session][:group_by], :column_names => session[entity_session][:column_names], :project => @project)
      @query.project = @project
    end
  end

  def retrieve_query_from_session(entity_query)
    entity_session = entity_query.name.underscore
    if session[entity_session]
      if session[entity_session][:id]
        @query = entity_query.find_by_id(session[entity_session][:id])
        return unless @query
      else
        @query = entity_query.new(:name => "_", :filters => session[entity_session][:filters], :group_by => session[entity_session][:group_by], :column_names => session[entity_session][:column_names])
      end
      if session[entity_session].has_key?(:project_id)
        @query.project_id = session[entity_session][:project_id]
      else
        @query.project = @project
      end
      @query
    end
  end

  def easy_query_group_entities_list(entities, query=nil, options={}, &block)
    if entities.is_a?(Array)
      if query && query.grouped?
        prepared_result = ActiveSupport::OrderedHash.new
        if query.group_by_column.is_a?(EasyQueryColumn)
          grouped_entities = entities.group_by{|i| query.group_by_column.value(i) }
        else
          grouped_entities = entities.group_by{|i| x = query.group_by_column.custom_value_of(i); (x.value if x).to_s }
        end
        counts = query.entity_count_by_group
        grouped_entities.each do |group, groups_entities|
          # sum
          sum = query.send(:summarize_entities, groups_entities, group)
          prepared_result[group] = {:entities => groups_entities, :sums => sum, :count => (counts[group] || groups_entities.count) }
        end
        entities = prepared_result
      else
        yield nil, {:entities => entities, :sums => {} }
        return
      end
    end
    raise ArgumentError, 'Please provide a prepared result to entities grouped list' unless entities.is_a?(Hash)

    entities.each do |group, attributes|
      yield group, attributes
    end
  end

  def easy_query_entity_list(entities)
    if entities.first.class.respond_to?(:each_with_easy_level)
      entities.first.class.each_with_easy_level(entities) do |entity, level|
        yield entity, level
      end
    else
      entities.each do |entity|
        yield entity, nil
      end
    end
  end

  def easy_query_column_header(column, options={})
    if !options[:disable_sort] && column.sortable
      sort_header_tag(column.name.to_s, :caption => column.caption, :default_order => column.default_order)
    else
      content_tag(:th, column.caption)
    end
  end

  def options_for_filters(filters, query)
    grouped_options = ActiveSupport::OrderedHash.new { |hash, key| hash[key] = Array.new }
    query_default_group_name = l("label_filter_group_#{query.class.name.underscore}")
    grouped_options[query_default_group_name]
    if query.entity == Issue
      grouped_options[l(:field_issue)+' '+l(:label_filter_group_custom_fields_suffix)]
      grouped_options[l(:label_filter_group_relations)]
    end
    filters.each do |field|
      group = field[1][:group] || l(:label_filter_group_unknown)
      grouped_options[group] << [ field[1][:name] || l(("field_"+field[0].to_s.gsub(/_id$/, "")).to_sym), field[0]] unless query.has_filter?(field[0])
    end

    grouped_options.delete_if{|key, value| value.blank?}

    # copied grouped_options_for_select ( due to ordering... )
    body = ''

    grouped_options.each do |group|
      body << content_tag(:optgroup, options_for_select(group[1]), :label => group[0])
    end

    body.html_safe
  end

  def format_value_for_export(entity, column, unformatted_value = nil, options={})
    if (column.is_a?(EasyEntityCustomAttribute)) && entity.respond_to?(:visible_custom_field_values)
      cv = entity.visible_custom_field_values.detect {|v| v.custom_field_id == column.custom_field.id}
      return show_value(cv, {:no_html => true}.merge(options))
    end
    # Entity is Class and it isn't instance. !
    # Sums rows
    if entity.is_a?(Class)
      entity_class = entity
      entity = nil
    else
      entity_class = entity.class
    end

    column_value = unformatted_value || (entity && column.value(entity))

    value = Sanitize.clean(format_entity_attribute(entity_class, column, column_value, {:entity => entity, :no_html => true}.merge(options)).to_s, :output => :html).strip
    value = value.to_s.gsub('.', l(:general_csv_decimal_separator)) if column_value && (column_value.is_a?(Float) || column_value.is_a?(BigDecimal))

    return value
  end

  # Returns a additional fast-icons buttons
  # - entity - instance of ...
  # - query - easy_query
  # - options - :no_link => true - no html links will be rendered
  #
  def easy_query_additional_beginning_buttons(query, entity, options={})
    return ''.html_safe if query.nil? || entity.nil?
    easy_query_additional_buttons_method = "#{query.class.name.underscore}_additional_beginning_buttons".to_sym

    additional_buttons = ''
    if respond_to?(easy_query_additional_buttons_method)
      additional_buttons = send(easy_query_additional_buttons_method, entity, options)
    end

    return additional_buttons.html_safe
  end

  def easy_query_additional_ending_buttons(query, entity, options={})
    return ''.html_safe if query.nil? || entity.nil?
    easy_query_additional_buttons_method = "#{query.class.name.underscore}_additional_ending_buttons".to_sym

    additional_buttons = ''
    if respond_to?(easy_query_additional_buttons_method)
      additional_buttons = send(easy_query_additional_buttons_method, entity, options)
    end

    return additional_buttons.html_safe
  end

  def easy_query_form_buttons_bottom(query, options= {})
    options[:easy_query_form_buttons_bottom_render_method] ||= 'list'
    method = "render_#{query.class.name.underscore}_form_buttons_bottom_on_#{options[:easy_query_form_buttons_bottom_render_method]}"
    if respond_to?(method)
      return send(method, query, options)
    end
  end

  def easy_query_group_by_title_content(query, count, sums={}, sum_type=:top, options={})
    a = Array.new

    a << count

    sums[sum_type].each do |column, sum|
      next unless query.columns.include?(column)
      if options[:plain]
        a << column.caption + ': ' + format_entity_attribute(query.entity, column, sum.to_f, options).to_s
      else
        a << column.caption + ': ' + format_html_entity_attribute(query.entity, column, sum.to_f, options).to_s
      end
    end

    return a.join(' , ').html_safe
  end

  def easy_query_summary_row(query, sums={}, sum_type=:bottom, options={})
    return ''.html_safe if sums[sum_type].blank?
    s = ''
    s << content_tag(:td)
    s << content_tag(:td, ''.html_safe, :class => 'checkbox') if options[:modal_selector] || options[:hascontextmenu]
    query.columns.each do |column|
      if column.sumable? && column.sumable_bottom?
        value = format_html_entity_attribute(query.entity, column, sums[sum_type][column])
        s << content_tag(:td, value, :class => column.name.to_s.underscore)
      else
        s << content_tag(:td, ''.html_safe, :class => column.name.to_s.underscore)
      end
    end
    s << content_tag(:td)

    return content_tag(:tr, s.html_safe, :class => 'summary')
  end

  def available_block_columns_tags(query)
    tags = ''.html_safe
    query.available_block_columns.each do |column|
      tags << content_tag('label', check_box_tag('easy_query[column_names][]', column.name.to_s, query.has_column?(column)) + " #{column.caption(true)}", :class => 'inline')
    end
    tags
  end

  def query_available_inline_columns_options(query)
    (query.available_inline_columns - query.columns).reject(&:frozen?).collect {|column| [column.caption(true), column.name]}
  end

  def query_selected_inline_columns_options(query)
    (query.inline_columns & query.available_inline_columns).reject(&:frozen?).collect {|column| [column.caption(true), column.name]}
  end


  # EXPORT
  def export_to_csv_old(entities,query)
    encoding = l(:general_csv_encoding)
    export = FCSV.generate(:col_sep => l(:general_csv_separator)) do |csv|
      # csv header fields
      headers = Array.new
      query.columns.each do |c|
        headers << c.caption
      end
      csv << headers.collect {|c| Redmine::CodesetUtil.safe_from_utf8(c, encoding) }
      # csv lines
      entities.each do |entity|
        fields = Array.new
        query.columns.each do |column|
          fields << format_value_for_export(entity, column)
        end
        csv << fields.collect {|c| Redmine::CodesetUtil.safe_from_utf8(c, encoding) }
      end
      total = Array.new
      query.columns.each do |column|
        if column.sumable?
          total << format_value_for_export(query.entity, column, query.entity_sum(column))
        else
          total << ''
        end
      end if query.columns.detect{|i| i.sumable?}
      csv << total.collect {|c| Redmine::CodesetUtil.safe_from_utf8(c, encoding) }
    end
    export
  end

  def export_to_csv(entities,query)
    if entities.is_a?(Array)
      return export_to_csv_old(entities, query)
    end
    encoding = l(:general_csv_encoding)
    export = FCSV.generate(:col_sep => l(:general_csv_separator)) do |csv|
      # csv header fields
      headers = Array.new
      query.columns.each do |c|
        headers << c.caption
      end
      csv << headers.collect {|c| Redmine::CodesetUtil.safe_from_utf8(c, encoding) }
      # csv lines
      entities.each do |group, attributes|
        attributes[:entities].each do |entity|
          fields = Array.new
          query.columns.each do |column|
            fields << format_value_for_export(entity, column)
          end
          csv << fields.collect {|c| Redmine::CodesetUtil.safe_from_utf8(c, encoding) }
        end
      end
      total = Array.new
      query.columns.each do |column|
        if column.sumable_bottom?
          total << format_value_for_export(query.entity, column, entities.values.inject(0){|mem,var| (var[:sums] && var[:sums][:bottom]) ? (mem += (var[:sums][:bottom][column] || 0).to_f) : nil; mem  })
        else
          total << ''
        end
      end if query.columns.detect{|i| i.sumable?}
      csv << total.collect {|c| Redmine::CodesetUtil.safe_from_utf8(c, encoding) }
    end
    export
  end

  def export_to_pdf(entities,query, options={})
    if entities.is_a?(Array)
      return export_to_pdf_old(entities, query)
    end

    EasyExtensions::Export::Pdf.new(entities, query, options).output
  end

  def export_to_pdf_old(entities,query)
    name = query.class.to_s.tableize
    pdf = ITCPDF.new(current_language)
    pdf.SetTitle(l("label_#{name}_plural"))
    pdf.alias_nb_pages
    pdf.footer_date = format_date(Date.today)
    pdf.AddPage("L")

    # title
    pdf.SetFontStyle('B',11)
    pdf.RDMCell(190,10, l("label_#{name}_plural"))
    pdf.Ln

    row_height = 5
    col_width = Array.new
    query.columns.each do |column|
      case column.name
      when :admin
        col_width << 0.4
      when :login, :firstname, :last_login_on, :created_on, :name
        col_width << 1
      when :lastname
        col_width << 1.5
      when :mail, :groups
        col_width << 2
      else
        col_width << 0.5
      end
    end
    ratio = 262.0 / col_width.inject(0) {|s,w| s += w}
    col_width = col_width.collect {|w| w * ratio}

    # headers
    pdf.SetFontStyle('B',8)
    pdf.SetFillColor(230, 230, 230)
    query.columns.each do |column|
      if column.name == :admin
        pdf.RDMCell(col_width[query.columns.index(column)], row_height, 'Adm.', 1, 0, 'L', 1)
      else
        pdf.RDMCell(col_width[query.columns.index(column)], row_height, column.caption.to_s, 1, 0, 'L', 1)
      end
    end
    pdf.Ln

    #rows
    pdf.SetFontStyle('',8)
    pdf.SetFillColor(255, 255, 255)
    previous_group = false
    entities.each do |entity|
      if query.grouped? && (group = query.group_by_column.value(entity)) != previous_group
        pdf.SetFontStyle('B',9)
        pdf.RDMCell(col_width.sum, row_height,
          (group.blank? ? 'None' : group.to_s) + " (#{query.entity_count_by_group[group]})",
          1, 1, 'L')
        pdf.SetFontStyle('',8)
        previous_group = group
      end
      query.columns.each do |column|
        pdf.RDMCell(col_width[query.columns.index(column)], row_height, format_value_for_export(entity, column), 1, 0, 'L', 1)
      end
      pdf.Ln
    end
    pdf.Output
  end

  def easy_render_csv_format_options_dialog(query, params)
    return if @csv_format_options_dialog_rendered
    @csv_format_options_dialog_rendered = true
    s = ''
    s << '<div id="csv-export-options" style="display:none;">'
    s << '  <h3 class="title">' + l(:label_export_options, :export_format => 'CSV') + '</h3>'
    s << form_tag(params.merge({:format => 'csv',:page=>nil}), :method => :get, :id => 'csv-export-form') do
      s2 = '<p>' +
        '  <label>' + radio_button_tag('easy_query[columns_to_export]', 'selected', true) + l(:description_selected_columns) + '</label><br />' +
        '  <label>' + radio_button_tag('easy_query[columns_to_export]', 'all' ) + l(:description_all_columns) + '</label>' +
        '</p>' +
        '<p>' +
        '  <label>' + check_box_tag('easy_query[column_names][]', 'description', query.has_column?(:description) ) + l(:field_description) + '</label>' +
        '</p>' +
        '<p class="buttons">' +
        '  ' + submit_tag(l(:button_export), :name => nil, :onclick => "hideModal(this);") +
        '  ' + submit_tag(l(:button_cancel), :name => nil, :onclick => "hideModal(this);", :type => 'button-2') +
        '</p>'
      s2.html_safe
    end
    s << '</div>'

    script = 'function() {'
    script << '   $(".other-formats .csv").click(function(e){'
    script << '     showModal("csv-export-options", "330px"); e.preventDefault(); '
    script << '     $("#csv-export-options").append( $("<input>").attr({name: "target_url", type: "hidden"}).val($(this).attr("href")) );'
    script << '   });'
    script << '   $("#csv-export-options form").submit(function(e){'
    script << '     e.preventDefault();'
    script << '     var target_url = $("#csv-export-options input[name=\'target_url\']").val();'
    script << '     if(!target_url.match(/\?/)) target_url+="?";'
    script << '     else target_url+="&";'
    script << '     window.location.replace(target_url+$(this).serialize()); '
    script << '   });'
    script << '}'
    s << javascript_tag('$(' + script + ')')

    s.html_safe
  end

end
