require 'redmine'

unless Object.const_defined?(:EASY_EXTENSIONS_ENABLED)
  if Object.const_defined?(:EasyExtensions)
    EASY_EXTENSIONS_ENABLED = true
  else
    EASY_EXTENSIONS_ENABLED = false
  end
end

Redmine::Plugin.register :easy_xml_helper do
  name(EASY_EXTENSIONS_ENABLED ? :easy_xml_helper_plugin_name : 'Easy XML Helper')
  author(EASY_EXTENSIONS_ENABLED ? :easy_xml_helper_plugin_author : 'Easy Software')
  author_url(EASY_EXTENSIONS_ENABLED ? :easy_xml_helper_plugin_author_url : 'http://www.easyredmine.com')
  description(EASY_EXTENSIONS_ENABLED ? :easy_xml_helper_plugin_description : '- helps with XML parsing')
  version '2013'
  visible(false) if EASY_EXTENSIONS_ENABLED
  should_be_disabled(false) if EASY_EXTENSIONS_ENABLED
  migration_order(300) if EASY_EXTENSIONS_ENABLED
  requires_redmine :version_or_higher => '2.1.2'
  requires_redmine_plugin(:easy_extensions, :version => '2013.08.04') if EASY_EXTENSIONS_ENABLED

  plugin_in_relative_subdirectory(File.join('easyproject', 'easy_plugins')) if EASY_EXTENSIONS_ENABLED
end