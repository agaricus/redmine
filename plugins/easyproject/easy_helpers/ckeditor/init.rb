Redmine::Plugin.register :ckeditor do
  visible false
  migration_order 100

  plugin_in_relative_subdirectory File.join('easyproject', 'easy_helpers')
end

require 'html_formatting/formatter'
require 'html_formatting/helper'

Redmine::WikiFormatting.register(:HTML, EasyPatch::HTMLFormatting::Formatter, EasyPatch::HTMLFormatting::Helper)
