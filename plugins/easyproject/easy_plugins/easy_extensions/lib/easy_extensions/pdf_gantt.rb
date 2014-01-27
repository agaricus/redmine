require 'easy_extensions/table_layout'
module EasyExtensions
  class PdfGantt
    include Redmine::I18n
    include ERB::Util
    include ActionView::Helpers::TextHelper
    include EntityAttributeHelper

    def initialize(options={})
      @project  = options[:project]
      @entities = options[:entities]
      @query    = options[:query]
      @theme    = options[:theme]
      @format   = options[:format]
      self.zoom = options[:zoom].to_sym

      self.relations = {}
      self.issue_ids = []
      self.occupied_vertical_lines = []
      set_additional_columns if @query
    end

    attr_accessor :columns, :query, :theme, :menu_width, :page_number, :relations, :issue_ids, :current_end_date
    attr_accessor :grid_top, :grid_bottom, :row_page, :occupied_vertical_lines, :menu_subject_width, :format
    attr_reader :project, :entities, :zoom, :margin
    attr_writer :grid_width

    def output(start_date)
      self.page_number = 1
      pdf.SetTitle("#{l(:label_gantt)} #{project}")
      pdf.alias_nb_pages
      pdf.footer_date = format_date(Date.today)
      end_date = calculate_end_date(start_date)
      if zoom == :day
        self.current_end_date = start_date - 1.day
      else
        self.current_end_date = start_date - (start_date.cwday + 6).days
      end
      begin
        self.current_end_date = render_page(current_end_date, :calendar => true, :project => true, :title => true)
        self.page_number += 1
      end while current_end_date < end_date
      pdf.output
    end

    private

    def calculate_end_date(start_date)
      end_date = start_date + 1.month
      entities.each do |group, values|
        values[:entities].each do |entity|
          entity_end_date = entity_to_gantt_data(entity)[:end]
          end_date = entity_end_date if entity_end_date && entity_end_date > end_date
          self.issue_ids << entity.id if entity.is_a?(Issue)
        end
      end
      end_date
    end

    def set_additional_columns
      self.columns = query.gantt_columns.first(5).collect { |d| {:data => d} }
      calculate_column_widths
    end

    # Rendering

    def render_page(start_date, options={})
      pdf.AddPage('L')
      pdf.SetX(15)

      render_title if options[:title]
      if theme
        render_logo(theme.logo) if theme.logo
      else
        render_logo(EasyGanttTheme.default_logo)
      end
      pdf.Ln
      @margin = pdf.GetX

      end_date = start_date + (desired_grid_width / day_width).round.days
      unless zoom == :day
        end_date -= (end_date.cwday - 1).days
      end

      self.current_end_date = end_date

      render_body(start_date, end_date, :menu => !!options[:menu], :project => !!options[:project])
      render_relations(start_date, end_date)

      end_date
    end

    def render_relations(start_date, end_date)
      current_menu_width = page_number == 1 ? menu_width : 0
      relation_format

      relations.values.select{|r| r[:stage] == :horizontal && r[:to_date] && (start_date..end_date).include?(r[:to_date])}.each do |r|
        r[:end][0] = margin + current_menu_width + (r[:to_date] - start_date) * day_width
        r.delete(:to_date)
      end

      # horizontal lines
      relations.values.select{|r| r[:stage] == :horizontal && row_page == r[:start_row]}.each do |r|
        if r[:end][0]
          r[:end][0] += 0.5
          r[:stage] = :vertical
        end

        x1 = r[:start][0] || current_menu_width + margin
        y1 = r[:start][1] + grid_top
        x2 = r[:end][0] || grid_end
        y2 = r[:start][1] + grid_top
        pdf.Line(x1, y1, x2, y2)

        r[:start][0] = nil
      end

      # vertical lines
      relations.values.select{|r| r[:stage] == :vertical && row_page >= r[:start_row]}.each do |r|
        x = r[:end][0] || current_menu_width + margin
        y1 = r[:start][1] ? r[:start][1] + grid_top : grid_top
        y2 = r[:end][1] ? r[:end][1] + grid_top : grid_bottom

        if occupied_vertical_lines.include?(x)
          pdf.Line(x, y1, x + 1, y1)
          x += 1
        end
        occupied_vertical_lines << x

        pdf.Line(x, y1, x, y2)

        r[:start][1] = nil
        if r[:end][1]
          # arrow
          pdf.Line(x - 0.5, y2 - 2, x, y2)
          pdf.Line(x + 0.5, y2 - 2, x, y2)

          r[:stage] = :done
        end
      end

    end

    def render_title
      title_format
      pdf.RDMCell(menu_subject_width, 20, project.to_s)
    end

    def render_logo(logo_path)
      begin
        img = pdf.imageToPNG(logo_path).path
        pdf.Image(
          img,
          220,
          16.5,
          0,
          7
        ) if img
      rescue
      end
    end

    def render_calendar(start_date, end_date)
      header_format
      render_menu_header if page_number == 1
      render_months(start_date, end_date)
      pdf.Ln
      @grid = []
      case zoom
      when :day
        render_days(start_date, end_date)
      when :week, :month
        render_weeks(start_date, end_date)
      end
      self.grid_width = pdf.GetX - margin
      self.grid_width = grid_width - menu_width if page_number == 1
    end

    def render_menu_header
      pdf.RDMCell(menu_subject_width, row_height * 2, '', 'LR', 0, 'L', 1)
      self.columns.each do |column|
        pdf.RDMCell(column[:width], row_height * 2, column[:data].caption, 'LR', 0, 'C', 1)
      end
    end

    def render_months(start_date, end_date)
      date = start_date
      left = margin
      left += menu_width if page_number == 1
      height = row_height
      while date < end_date
        new_date = date - (date.day - 1).days + 1.month
        new_date = end_date if new_date > end_date
        width = (new_date - date) * day_width
        pdf.SetX(left)
        month_text = "#{date.year}-#{date.month}"
        pdf.RDMCell(width, height, pdf.GetStringWidth(month_text) > width ? '' : month_text, 'LRB', 0, 'C', 1)
        left += width
        date = new_date
      end

    end

    def render_weeks(start_date, end_date)
      date = start_date
      pdf.SetFontStyle('', 6) if zoom == :month

      left = margin
      left += menu_width if page_number == 1
      height = row_height
      if date.cwday != 1
        left += (date.cwday - 1) * day_width
        date += (7 - date.cwday).days
      end
      while date < end_date
        new_date = date + 1.week
        new_date = end_date if new_date > end_date
        width = (new_date - date) * day_width
        pdf.SetX(left)
        month_text = date.cweek.to_s
        @grid << [left, width]
        pdf.RDMCell(width, height, pdf.GetStringWidth(month_text) > width ? '' : month_text, 'LT', 0, 'C', 1)
        left += width
        date = new_date
      end
    end

    def render_days(start_date, end_date)
      date = start_date
      left = margin
      left += menu_width if page_number == 1
      while date < end_date
        pdf.SetX(left)
        @grid << [left, day_width]
        pdf.RDMCell(day_width, row_height, date.day, 'LT', 0, 'C', 1)
        left += day_width
        date = date + 1.day
      end
    end

    def render_body(start_date, end_date, options={})
      render_calendar(start_date, end_date)
      grid_format
      pdf.Ln
      self.grid_top = pdf.GetY
      self.row_page = 1
      if project && query.group_by != 'project' && !(entities.keys == [nil] && entities[nil][:entities].blank?)
        render_line(start_date, entity_to_gantt_data(project))
      end
      entities.each do |group, values|
        render_line(start_date, entity_to_gantt_data(group)) if group
        self.grid_bottom = pdf.GetY
        values[:entities].each do |entity|
          if pdf.GetY > max_y
            render_relations(start_date, end_date)
            pdf.AddPage("L")
            render_calendar(start_date, end_date)
            self.grid_top = pdf.GetY
            self.row_page += 1
            grid_format
            pdf.Ln
            self.grid_top = pdf.GetY
          end
          render_line(start_date, entity_to_gantt_data(entity))
          self.grid_bottom = pdf.GetY
        end
      end
    end

    def render_line(start_date, data)
      if data[:type] == :issue
        issue_menu_format
        current_row_height = multicell_height('  ' * data[:level] + data[:menu_title], menu_subject_width)
      else
        current_row_height = row_height
      end

      pdf.SetX(margin)
      if page_number == 1
        case data[:type]
        when :issue
          issue_menu_format
          pdf.RDMMultiCell(menu_subject_width, row_height, '  ' * data[:level] + data[:menu_title], 'LTBR', '', 0, 0)
          columns.each do |column|
            value = column[:data].value(data[:entity])
            formatted_value = format_entity_attribute(Issue, column[:data], value).to_s
            pdf.GetX
            pdf.RDMCell(column[:width], current_row_height, formatted_value, 'LTBR', 0, 'C', 0)
          end
        when :project
          project_menu_format
          pdf.RDMCell(menu_width, current_row_height, '  ' * data[:level] + data[:menu_title], 'LTBR', 0, '', 1)
        when :version
          version_menu_format
          pdf.RDMCell(menu_width, current_row_height, '  ' * data[:level] + data[:menu_title], 'LTBR', 0, '', 1)
        end

        pdf.SetX(margin + menu_width)
        pdf.RDMCell(grid_width, current_row_height, '', 'LR', 0, '', 1)
      end

      render_line_grid(current_row_height)

      case data[:type]
      when :issue, :project
        render_worm(start_date, data)
      when :version
        render_version_rhombus(start_date, data)
      end

      pdf.SetXY(margin, pdf.GetY + current_row_height)
    end

    def render_line_grid(row_height)
      x = pdf.GetX
      @grid.each do |cell_position|
        pdf.SetX(cell_position[0])
        pdf.RDMCell(cell_position[1], row_height, '', 'LTBR')
      end
      pdf.SetX(x)
    end

    def render_worm(start_date, data)
      return if data[:start].blank? || data[:end].blank?
      current_menu_width = page_number == 1 ? menu_width : 0
      total_left = margin + current_menu_width + (data[:start] - start_date) * day_width
      return if total_left > grid_end

      total_width = (data[:end] - data[:start]) * day_width
      return if total_left + total_width <= margin + current_menu_width

      if total_left < current_menu_width + margin
        width = (data[:end] - start_date) * day_width
        left = current_menu_width + margin
      else
        width = total_width
        left = total_left
      end

      case data[:type]
      when :project
        project_worm_format
      when :issue
        issue_worm_format
        data[:entity].relations_from.select{|r| r.relation_type == 'precedes' && issue_ids.include?(r.issue_to_id)}.each do |r|
          unless relations[r.id]
            if width + left <= grid_end
              relations[r.id] = {
                :start => [left + width, pdf.GetY + 2.5 - grid_top],
                :end => [nil, nil],
                :to_id => r.issue_to_id,
                :to_date => r.issue_to.start_date || r.issue_to.due_date,
                :start_row => row_page,
                :stage => :horizontal
              }
            end
          end
        end

        relations.values.select{|r| r[:to_id] == data[:entity].id}.each do |r|
          if left == total_left
            r.delete(:to_id)
            r[:end] = [r[:end][0] || left, pdf.GetY + 1 - grid_top]
          end
        end
      end

      data[:left] = left
      data[:total_left] = total_left
      data[:width] = width

      pdf.SetY(pdf.GetY + 1)
      pdf.SetX(left)
      pdf.RDMCell(width + left > grid_end ? grid_end - left : width, 3, '', 0, 0, '', 1)

      if data[:done_ratio] && data[:done_ratio] > 0
        progress_width = total_width * data[:done_ratio] / 100
        unless total_left + progress_width < margin + current_menu_width
          if total_left < current_menu_width + margin
            progress_width -= (total_width - width)
          end
          case data[:type]
          when :project
            project_worm_progress_format
          when :issue
            issue_worm_progress_format
          end
          pdf.SetX(left)
          pdf.RDMCell(progress_width + left > grid_end ? grid_end - left : progress_width, 3, '', 0, 0, '', 1)
        end
      end
      pdf.SetY(pdf.GetY - 1)
    end

    def render_version_rhombus(start_date, data)
      rhombus_format
      rhombus_size = 3
      current_menu_width = page_number == 1 ? menu_width : 0
      left = margin + current_menu_width + (data[:start]  - start_date) * day_width + (day_width - rhombus_size)/2
      return if left < margin + current_menu_width || left > grid_end
      img = pdf.imageToPNG(File.join(EASY_EXTENSIONS_DIR, 'assets', 'images', 'easygantt', 'rhombus.gif')).try(:path)
      pdf.Image(
        img,
        left,
        pdf.GetY + (row_height - rhombus_size)/2,
        rhombus_size,
        rhombus_size
      ) if img
      pdf.SetX(left + 5)
      pdf.RDMCell(20, row_height, format_date(data[:start])) if data[:start]
    end

    # Internals

    def pdf
      @pdf ||= ::Redmine::Export::PDF::ITCPDF.new(current_language, 'L', format)
    end

    def zoom=(z)
      @zoom ||= [:day, :week, :month].include?(z) ? z : :day
    end

    def entity_to_gantt_data(entity)
      data = {
        :entity => entity,
        :type => entity.class.name.downcase.to_sym,
        :level => project ? 1 : 0
      }
      if entity.is_a?(Issue)
        data[:menu_title] = entity.to_s
        if entity.start_date || entity.due_date
          data[:start]      = entity.start_date
          data[:end]        = (entity.due_date || entity.start_date) + 1.day
        end
        data[:done_ratio] = entity.done_ratio
        data[:level]      += entity.easy_level if entity.easy_level
      elsif entity.is_a?(Version)
        data[:menu_title] = entity.name
        data[:start]      = entity.effective_date
        data[:end]        = data[:start]
      elsif entity.is_a?(Project)
        data[:menu_title] = entity.name
        data[:start]      = entity.start_date
        data[:end]        = (entity.due_date || entity.start_date) + 1.day unless entity.start_date.blank?
        data[:done_ratio] = entity.completed_percent
        data[:level]      = 0
      end
      data[:start] = data[:start].to_date if data[:start]
      data[:end] = data[:end].to_date if data[:end]
      data
    end

    # Layout

    def multicell_height(str, width)
      x, y = pdf.GetX, pdf.GetY
      pdf.SetX(1000)
      pdf.RDMMultiCell(width, row_height, str, '', 'L', 0, 1)
      new_y = pdf.GetY
      pdf.SetXY(x, y)
      new_y - y
    end

    def width
      format == 'A4' ? 275 : 400
    end

    def max_y
      format == 'A4' ? 180 : 270
    end

    def menu_subject_width
      @menu_subject_width ||= 100
    end

    def desired_grid_width
      if page_number == 1
        width - menu_width
      else
        width
      end
    end

    def grid_width
      @grid_width
    end

    def grid_end
      @grid.last[0] + @grid.last[1]
    end

    def max_subject_chars
      45
    end

    def row_height
      5
    end

    def grid_column_width
      6.0
    end

    def day_width
      @day_width ||= case zoom
      when :day
        grid_column_width
      when :week
        grid_column_width / 7
      when :month
        grid_column_width / 14
      end
    end

    def calculate_column_widths
      issue_menu_format
      max_text_widths = [0]
      columns.each do |column|
        max_text_widths << pdf.get_string_width(column[:data].caption)
      end

      entities.each do |group, values|
        values[:entities].each do |entity|
          if entity.is_a?(Issue)
            subject_width = pdf.get_string_width(entity.subject)
            max_text_widths[0] = subject_width if subject_width > max_text_widths[0]

            columns.each_with_index do |column, i|
              value = column[:data].value(entity)
              formatted_value = format_entity_attribute(Issue, column[:data], value).to_s
              text_width = pdf.get_string_width(formatted_value)
              max_text_widths[i + 1] = text_width if text_width > max_text_widths[i + 1]
            end
          end
        end
      end

      widths = EasyExtensions::TableLayout::auto_column_widths(100, max_text_widths, max_text_widths, 3)
      self.menu_subject_width = widths[0] if menu_subject_width > widths[0]
      self.menu_width = menu_subject_width
      widths[1..-1].each_with_index do |w, i|
        columns[i][:width] = w
        self.menu_width += w
      end
    end

    # Formatting

    def title_format
      pdf.SetFontStyle('B', 15)
    end

    def grid_format
      pdf.SetLineWidth(0.1)
      pdf.SetDrawColor(175)
      pdf.SetTextColor(0, 0, 0)
      pdf.SetFillColor(255, 255, 255)
    end

    def relation_format
      pdf.SetLineWidth(0.1)
      pdf.SetDrawColor(0, 0, 255)
    end

    def header_format
      pdf.SetLineWidth(0.05)
      pdf.SetFontStyle('', 9)
      if theme
        pdf.SetTextColor(theme.header_font_color_r, theme.header_font_color_g, theme.header_font_color_b)
        pdf.SetDrawColor(theme.header_font_color_r, theme.header_font_color_g, theme.header_font_color_b)
        pdf.SetFillColor(theme.header_color_r, theme.header_color_g, theme.header_color_b)
      else
        pdf.SetDrawColor(255)
        pdf.SetTextColor(255, 255, 255)
        pdf.SetFillColor(57, 171, 227)
      end
    end

    def issue_menu_format
      pdf.SetFillColor(255)
      pdf.SetFontStyle('', 8)
    end

    def issue_worm_format
      pdf.SetFillColor(200, 200, 200)
    end

    def issue_worm_progress_format
      pdf.SetFillColor(137, 197, 230)
    end

    def project_menu_format
      pdf.SetFillColor(255)
      pdf.SetFontStyle('B', 9)
    end

    def project_worm_format
      pdf.SetFillColor(251, 222, 151)
    end

    def project_worm_progress_format
      pdf.SetFillColor(251, 186, 24)
    end

    def rhombus_format
      pdf.SetFillColor(255)
      pdf.SetFontStyle('', 8)
    end

    def version_menu_format
      pdf.SetFillColor(255)
      pdf.SetFontStyle('IB', 8)
    end

  end
end
