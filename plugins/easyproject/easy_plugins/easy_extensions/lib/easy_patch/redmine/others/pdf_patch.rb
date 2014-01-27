module EasyPatch
  module ITCPDFPatch

    def self.included(base)
      base.send(:include, InstanceMethods)
      base.class_eval do

        alias_method_chain :RDMCell, :easy_extensions
        alias_method_chain :RDMMultiCell, :easy_extensions
        alias_method_chain :imageToPNG, :easy_extensions

        def initialize(lang, orientation='P', format='A4')
          @@k_path_cache = Rails.root.join('tmp', 'pdf')
          FileUtils.mkdir_p @@k_path_cache unless File::exist?(@@k_path_cache)
          set_language_if_valid lang
          pdf_encoding = l(:general_pdf_encoding).upcase
          super(orientation, 'mm', format, (pdf_encoding == 'UTF-8'), pdf_encoding)
          case current_language.to_s.downcase
          when 'vi'
            @font_for_content = 'DejaVuSans'
            @font_for_footer  = 'DejaVuSans'
          else
            case pdf_encoding
            when 'UTF-8'
              @font_for_content = 'FreeSans'
              @font_for_footer  = 'FreeSans'
            when 'CP949'
              extend(PDF_Korean)
              AddUHCFont()
              @font_for_content = 'UHC'
              @font_for_footer  = 'UHC'
            when 'CP932', 'SJIS', 'SHIFT_JIS'
              extend(PDF_Japanese)
              AddSJISFont()
              @font_for_content = 'SJIS'
              @font_for_footer  = 'SJIS'
            when 'GB18030'
              extend(PDF_Chinese)
              AddGBFont()
              @font_for_content = 'GB'
              @font_for_footer  = 'GB'
            when 'BIG5'
              extend(PDF_Chinese)
              AddBig5Font()
              @font_for_content = 'Big5'
              @font_for_footer  = 'Big5'
            else
              @font_for_content = 'Arial'
              @font_for_footer  = 'Helvetica'
            end
          end
          SetCreator(Redmine::Info.app_name)
          SetFont(@font_for_content)
          @outlines = []
          @outlineRoot = nil
          @fontlist = ["helvetica"]
        end


        def RDMMultiCellWithSanitize(w, h, txt='', border=0, align='J', fill=0, ln=1)
          txt = Sanitize.clean(txt, :output => :html)
          RDMMultiCell(w, h, txt, border, align, fill, ln)
        end

        def openHTMLTagHandler(tag, attrs, fill=0)
          if tag == 'hr' && attrs['width'] && attrs['width'] =~ /\D+/
            attrs.delete('width')
          end
          super(tag, attrs, fill)
        end

      end
    end

    module InstanceMethods

      def RDMCell_with_easy_extensions(w ,h=0, txt="", border=0, ln=0, align='', fill=0, link='')
        Cell(w, h, fix_text_encoding(txt.to_s.dup), border, ln, align, fill, link)
      end

      def RDMMultiCell_with_easy_extensions(w, h=0, txt='', border=0, align='', fill=0, ln=1)
        MultiCell(w, h, fix_text_encoding(txt.to_s.dup), border, align, fill, ln)
      end

      def imageToPNG_with_easy_extensions(file)
        return unless Object.const_defined?(:Magick)

        img = Magick::ImageList.new(file)
        img.format = 'PNG'   # convert to PNG from gif
        img.alpha(Magick::BackgroundAlphaChannel)      # PNG alpha channel delete

        #use a temporary file....
        tmpFile = Tempfile.new(['', '_' + File::basename(file) + '.png'], self.k_path_cache);
        tmpFile.binmode
        tmpFile.print img.to_blob
        tmpFile
      ensure
        tmpFile.close if tmpFile
      end
    end

  end
end
EasyExtensions::PatchManager.register_other_patch 'Redmine::Export::PDF::ITCPDF', 'EasyPatch::ITCPDFPatch'


module EasyPatch
  module PDFPatch

    def self.included(base)
      base.extend(ClassMethods)
      base.send(:include, InstanceMethods)

      base.class_eval do

        include ActionView::Helpers::TagHelper
        include EasyJournalHelper

        alias_method_chain :render_table_header, :easy_extensions
        alias_method_chain :issue_to_pdf, :easy_extensions
        alias_method_chain :fetch_row_values, :easy_extensions

      end
    end

    module InstanceMethods

      def render_table_header_with_easy_extensions(pdf, query, col_width, row_height, table_width)
        render_table_header_without_easy_extensions(pdf, query, col_width, row_height, table_width)
        return if @table_header_sums_rendered
        @table_header_sums_rendered = true
        pdf.SetFontStyle('B',8)
        pdf.SetFillColor(255, 255, 202)

        base_x = pdf.GetX
        base_y = pdf.GetY
        max_height = row_height
        first_sumable = nil
        sum_widths = []
        query.inline_columns.each_with_index do |column, i|
          next unless first_sumable || column.sumable?
          unless first_sumable
            first_sumable = i
            pdf.RDMMultiCell(col_width[0..i-1].sum, row_height, l(:label_total_total), "T", 'L', 1)
            pdf.SetXY(base_x + col_width[0..i-1].sum, base_y);
            sum_widths = [col_width[0..i-1].sum] + col_width[i..-1]
          end

          col_x = pdf.GetX
          if column.sumable?
            pdf.RDMMultiCell(col_width[i], row_height, query.entity_sum(column).to_s, "T", 'L', 1)
          else
            pdf.RDMMultiCell(col_width[i], row_height, '', "T", 'L', 1)
          end
          max_height = (pdf.GetY - base_y) if (pdf.GetY - base_y) > max_height
          pdf.SetXY(col_x + col_width[i], base_y);
        end

        issues_to_pdf_draw_borders(pdf, base_x, base_y, base_y + max_height, 0, sum_widths)

        pdf.SetY(base_y + max_height);
        pdf.SetFontStyle('',8)
        pdf.SetFillColor(255, 255, 255)
      end

      # fetch row values
      def fetch_row_values_with_easy_extensions(issue, query, level)
        query.inline_columns.collect do |column|
          s = if column.is_a?(EasyQueryCustomFieldColumn)
            cv = issue.visible_custom_field_values.detect {|v| v.custom_field_id == column.custom_field.id}
            show_value(cv, :no_html => true)
          else
            value = issue.send(column.name)

            case column.name
            when :subject
              value = "  " * level + value
            when :sum_of_timeentries, :remaining_timeentries
              value = ('%.2f' % value) if value
            end

            if value.is_a?(Date)
              format_date(value)
            elsif value.is_a?(Time)
              format_time(value)
            elsif value.is_a?(Array)
              if value.empty?
                ''
              elsif value.first.class.name == 'Watcher'
                value.collect{|w| w.user.name}.join(', ')
              else
                value.join(', ')
              end
            else
              value
            end
          end
          s.to_s
        end
      end

      # Returns a PDF string of a single issue
      def issue_to_pdf_with_easy_extensions(issue, assoc={})
        pdf = Redmine::Export::PDF::ITCPDF.new(current_language)
        buf = "#{issue.project} - #{issue.tracker} "
        pdf.SetTitle(buf)
        pdf.alias_nb_pages
        pdf.footer_date = format_date(Date.today)
        pdf.AddPage
        pdf.SetFontStyle('B',11)

        pdf.RDMMultiCell(190, 5, buf)
        pdf.SetFontStyle('',8)
        base_x = pdf.GetX
        i = 1
        issue.ancestors.visible.each do |ancestor|
          pdf.SetX(base_x + i)
          buf = "#{ancestor.tracker} (#{ancestor.status.to_s}): #{ancestor.to_s}"
          pdf.RDMMultiCell(190 - i, 5, buf)
          i += 1 if i < 35
        end
        pdf.SetFontStyle('B',11)
        pdf.RDMMultiCell(190 - i, 5, issue.to_s)
        pdf.SetFontStyle('',8)
        pdf.RDMMultiCell(190, 5, "#{format_time(issue.created_on)} - #{issue.author.name}")
        pdf.Ln

        left = []
        left << [l(:field_status), issue.status]
        left << [l(:field_priority), issue.priority]
        left << [l(:field_assigned_to), issue.assigned_to] unless issue.disabled_core_fields.include?('assigned_to_id')
        left << [l(:field_category), issue.category] unless issue.disabled_core_fields.include?('category_id')
        left << [l(:field_fixed_version), issue.fixed_version] unless issue.disabled_core_fields.include?('fixed_version_id')

        right = []
        right << [l(:field_start_date), format_date(issue.start_date)] unless issue.disabled_core_fields.include?('start_date')
        right << [l(:field_due_date), format_date(issue.due_date)] unless issue.disabled_core_fields.include?('due_date')
        right << [l(:field_done_ratio), "#{issue.done_ratio}%"] unless issue.disabled_core_fields.include?('done_ratio')
        right << [l(:field_estimated_hours), l_hours(issue.estimated_hours)] unless issue.disabled_core_fields.include?('estimated_hours')
        right << [l(:label_spent_time), l_hours(issue.total_spent_hours)] if User.current.allowed_to?(:view_time_entries, issue.project)

        rows = left.size > right.size ? left.size : right.size
        while left.size < rows
          left << nil
        end
        while right.size < rows
          right << nil
        end

        if EasySetting.value(:show_issue_custom_field_values_layout) == 'two_columns'
          half = (issue.visible_custom_field_values.size / 2.0).ceil
          issue.visible_custom_field_values.each_with_index do |custom_value, i|
            (i < half ? left : right) << [custom_value.custom_field.translated_name, show_value(custom_value, :no_html => true)]
          end
        end

        rows = left.size > right.size ? left.size : right.size
        rows.times do |i|
          item = left[i]
          pdf.SetFontStyle('B',9)
          pdf.RDMCell(35,5, item ? "#{item.first}:" : "")
          pdf.SetFontStyle('',9)
          pdf.RDMMultiCellWithSanitize(60,5, item ? item.last.to_s : "", '', 'J', 0, 0)

          item = right[i]
          pdf.SetFontStyle('B',9)
          pdf.RDMCell(35,5, item ? "#{item.first}:" : "")
          pdf.SetFontStyle('',9)
          pdf.RDMMultiCellWithSanitize(60,5, item ? item.last.to_s : "", '', 'J', 0, 1)
          # pdf.Ln
        end

        if EasySetting.value(:show_issue_custom_field_values_layout) == 'one_column'
          pdf.SetFontStyle('B',9)
          pdf.RDMCell(35+155, 5, '', "T", 1)
          issue.visible_custom_field_values.each do |custom_value|
            pdf.SetFontStyle('B',9)
            pdf.RDMMultiCell(35,5, custom_value.custom_field.translated_name,'', 'J', 0, 0)
            pdf.SetFontStyle('',9)
            pdf.RDMMultiCellWithSanitize(155,5, show_value(custom_value, :no_html => true))
            pdf.Ln
          end
        end

        pdf.SetFontStyle('B',9)
        pdf.RDMCell(35+155, 5, l(:field_description), "B", 1)
        pdf.SetFontStyle('',9)

        # Set resize image scale
        pdf.SetImageScale(1.6)
        pdf.RDMwriteHTMLCell(35+155, 5, 0, 0,
          remove_img_from_exported_html_content(issue.description.to_s), issue.attachments, "B")

        unless issue.leaf?
          # for CJK
          truncate_length = ( l(:general_pdf_encoding).upcase == "UTF-8" ? 90 : 65 )

          pdf.SetFontStyle('B',9)
          pdf.RDMCell(35+155,5, l(:label_subtask_plural) + ":", "T")
          pdf.Ln
          issue_list(issue.descendants.visible.sort_by(&:lft)) do |child, level|
            buf = truncate("#{child.tracker} # #{child.id}: #{child.subject}",
              :length => truncate_length)
            level = 10 if level >= 10
            pdf.SetFontStyle('',8)
            pdf.RDMCell(35+135,5, (level >=1 ? "  " * level : "") + buf, "")
            pdf.SetFontStyle('B',8)
            pdf.RDMCell(20,5, child.status.to_s, "")
            pdf.Ln
          end
        end

        relations = issue.relations.select { |r| r.other_issue(issue).visible? }
        unless relations.empty?
          # for CJK
          truncate_length = ( l(:general_pdf_encoding).upcase == "UTF-8" ? 80 : 60 )

          pdf.SetFontStyle('B',9)
          pdf.RDMCell(35+155,5, l(:label_related_issues) + ":", "T")
          pdf.Ln
          relations.each do |relation|
            buf = ""
            buf += "#{l(relation.label_for(issue))} "
            if relation.delay && relation.delay != 0
              buf += "(#{l('datetime.distance_in_words.x_days', :count => relation.delay)}) "
            end
            if Setting.cross_project_issue_relations?
              buf += "#{relation.other_issue(issue).project} - "
            end
            buf += "#{relation.other_issue(issue).tracker}" +
              " # #{relation.other_issue(issue).id}: #{relation.other_issue(issue).subject}"
            buf = truncate(buf, :length => truncate_length)
            pdf.SetFontStyle('', 8)
            pdf.RDMCell(35+155-60, 5, buf, "L")
            pdf.SetFontStyle('B',8)
            pdf.RDMCell(20,5, relation.other_issue(issue).status.to_s, "")
            pdf.RDMCell(20,5, format_date(relation.other_issue(issue).start_date), "")
            pdf.RDMCell(20,5, format_date(relation.other_issue(issue).due_date), "")
            pdf.Ln
          end
        end
        pdf.RDMCell(190,5, "", "T")
        pdf.Ln

        if issue.changesets.any? && User.current.allowed_to?(:view_changesets, issue.project)
          pdf.SetFontStyle('B',9)
          pdf.RDMCell(190,5, l(:label_associated_revisions), "B")
          pdf.Ln
          for changeset in issue.changesets
            pdf.SetFontStyle('B',8)
            csstr  = "#{l(:label_revision)} #{changeset.format_identifier} - "
            csstr += format_time(changeset.committed_on) + " - " + changeset.author.to_s
            pdf.RDMCell(190, 5, csstr)
            pdf.Ln
            unless changeset.comments.blank?
              pdf.SetFontStyle('',8)
              pdf.RDMwriteHTMLCell(190,5,0,0,
                changeset.comments.to_s, issue.attachments, "")
            end
            pdf.Ln
          end
        end

        if assoc[:journals].present?
          pdf.SetFontStyle('B',9)
          pdf.RDMCell(190,5, l(:label_history), "B")
          pdf.Ln
          assoc[:journals].each do |journal|
            pdf.SetFontStyle('B',8)
            title = "##{journal.indice} - #{format_time(journal.created_on)} - #{journal.user}"
            title << " (#{l(:field_private_notes)})" if journal.private_notes?
            pdf.RDMCell(190,5, title)
            pdf.Ln
            pdf.SetFontStyle('I',8)
            details_to_strings(journal.visible_details, true).each do |string|
              pdf.RDMMultiCellWithSanitize(190,5, "- " + string)
            end
            if journal.notes?
              pdf.Ln unless journal.details.empty?
              pdf.SetFontStyle('',8)
              pdf.RDMwriteHTMLCell(190,5,0,0,
                remove_img_from_exported_html_content(journal.notes.to_s), issue.attachments, '')
            end
            pdf.Ln
          end
        end

        if issue.attachments.any?
          pdf.SetFontStyle('B',9)
          pdf.RDMCell(190,5, l(:label_attachment_plural), "B")
          pdf.Ln
          for attachment in issue.attachments
            pdf.SetFontStyle('',8)
            pdf.RDMCell(80,5, attachment.filename)
            pdf.RDMCell(20,5, number_to_human_size(attachment.filesize),0,0,"R")
            pdf.RDMCell(25,5, format_date(attachment.created_on),0,0,"R")
            pdf.RDMCell(65,5, attachment.author.name,0,0,"R")
            pdf.Ln
          end
        end
        pdf.Output
      end

      def remove_img_from_exported_html_content(txt)
        # TODO: create file in temp and replace hash to pth to image in temp...
        # f =File.new("img.png", "w"); f.puts Base64.decode64(Nokogiri::HTML::DocumentFragment.parse(Issue.find(19301).description).css("img").first['src'].split(',').last); f.close
        node = Nokogiri::HTML::DocumentFragment.parse(txt)
        node.css('img').each do |img|
          img.remove
        end

        return node.to_s
      end


    end

    module ClassMethods
    end
  end
end
EasyExtensions::PatchManager.register_other_patch 'Redmine::Export::PDF', 'EasyPatch::PDFPatch'
