module EasyExtensions
  module TableLayout

    def self.auto_column_widths(max_table_width, text_widths, max_widths, padding=0)
      widths = []
      text_widths.each_with_index do |width, i|
        widths << [width, max_widths[i]].min + 2 * padding
      end
      widths
    end

  end
end
