require 'easy_extensions/easy_extensions'

#Mime::Type.register 'text/calendar', :ics
Mime::Type.register_alias 'text/html', :mobile

if EasyExtensions::EasyProjectSettings.enable_copying_files_on_restart
  begin
    FileUtils.cp("#{EasyExtensions::PATH_TO_EASYPROJECT_ROOT}/easy_plugins/easy_extensions/lib/easy_patch/to_copy/404.html", "#{Rails.root}/public/404.html")
    FileUtils.cp("#{EasyExtensions::PATH_TO_EASYPROJECT_ROOT}/easy_plugins/easy_extensions/lib/easy_patch/to_copy/500.html", "#{Rails.root}/public/500.html")
    FileUtils.cp("#{EasyExtensions::PATH_TO_EASYPROJECT_ROOT}/easy_plugins/easy_extensions/lib/easy_patch/to_copy/browserconfig.xml", "#{Rails.root}/public/browserconfig.xml")
    FileUtils.cp("#{EasyExtensions::PATH_TO_EASYPROJECT_ROOT}/easy_plugins/easy_extensions/assets/images/favicon.ico", "#{Rails.root}/public/favicon.ico")
  rescue
  end
end

# Load plurals langfiles.
I18n.load_path += Dir[File.join(EasyExtensions::EASY_EXTENSIONS_DIR, 'config', 'locales', '*.{rb}')]

ActiveRecord::Base.observers += [:issue_invitation_observer]

Dir[File.dirname(__FILE__) + '/lib/easy_patch/core/*.rb'].each {|file| require_dependency file }
Dir[File.dirname(__FILE__) + '/lib/easy_patch/rails/*.rb'].each {|file| require_dependency file }
Dir[File.dirname(__FILE__) + '/lib/easy_patch/plugins/*.rb'].each {|file| require_dependency file }
Dir[File.dirname(__FILE__) + '/lib/easy_patch/redmine/others/*.rb'].each {|file| require_dependency file }
Dir[File.dirname(__FILE__) + '/lib/easy_patch/redmine/controllers/*.rb'].each {|file| require_dependency file }
Dir[File.dirname(__FILE__) + '/lib/easy_patch/redmine/helpers/*.rb'].each {|file| require_dependency file }
Dir[File.dirname(__FILE__) + '/lib/easy_patch/redmine/models/*.rb'].each {|file| require_dependency file }

require_dependency 'easy_extensions/easy_translator'

require 'easy_extensions/menus'

ActionDispatch::Reloader.to_prepare do
  Dir[File.dirname(__FILE__) + '/lib/easy_extensions/validators/*.rb'].each {|file| require file }

  require_dependency 'easy_extensions/hooks'

  require_dependency 'easy_extensions/permissions'
  require_dependency 'easy_extensions/internals'

  require_dependency 'easy_extensions/easy_xml_data/importer'
  require_dependency 'easy_version_category'
  require_dependency 'easy_extensions/yaml_encoder'
  require_dependency 'easy_extensions/pdf_gantt'
  require_dependency 'easy_extensions/easy_external_authentications/easy_external_authentication_provider'

  CustomFieldsHelper::CUSTOM_FIELDS_TABS << {:name => 'DocumentCustomField', :partial => 'custom_fields/index', :label => :label_document_plural}

  Redmine::Search.map do |search|
    search.unregister :projects
  end

  Redmine::Search.map do |search|
    search.register :project
  end

  Redmine::MimeType.register_mime_type 'application/eml', 'eml'

  #EasyExtensions.debug_mode = true
  if EasyExtensions.debug_mode
    puts 'WARNING: starting in a debug mode!'
    require 'easy_extensions/easy_performance_watcher'
    Dir[File.dirname(__FILE__) + '/lib/easy_patch/debug/*.rb'].each {|file| require file }
  end


  require 'easy_extensions/easy_repeaters'

  EasyExtensions::EntityRepeater.map do |mapper|
    mapper.register EasyExtensions::IssueRepeater.new
  end

end

EpmRedmineModule.ensure_all

require 'easy_extensions/easy_scheduler'
Dir[File.dirname(__FILE__) + '/lib/easy_extensions/scheduler_tasks/*.rb'].each {|file| require file }
#Dir[File.dirname(__FILE__) + '/lib/easy_extensions/scheduler_tasks/page_heaters/*.rb'].each {|file| require file }

#EasyExtensions::EasyProjectHeaterSchedulerTask.map do |heater_task|
#  heater_task.add_page_heater EasyExtensions::EasyProjectPageHeaterMyPage.new
#  heater_task.add_page_heater EasyExtensions::EasyProjectPageHeaterProjectOverview.new
#end

require 'easy_extensions/easyproject_maintenance'
EasyExtensions::Orphans.map do |orphans_mapper|
  orphans_mapper.register_plugin EasyExtensions::EasyExtensionsOrphans.new
end

Dir[File.dirname(__FILE__) + '/lib/easy_extensions/easy_lookups/*.rb'].each {|file| require file }
EasyExtensions::EasyLookups::EasyLookup.map do |easy_lookup|
  easy_lookup.register EasyExtensions::EasyLookups::EasyLookupDocument.new
  easy_lookup.register EasyExtensions::EasyLookups::EasyLookupGroup.new
  easy_lookup.register EasyExtensions::EasyLookups::EasyLookupIssue.new
  easy_lookup.register EasyExtensions::EasyLookups::EasyLookupProject.new
  easy_lookup.register EasyExtensions::EasyLookups::EasyLookupUser.new
  easy_lookup.register EasyExtensions::EasyLookups::EasyLookupVersion.new
end

Redmine::CustomFieldFormat.available = {}
Redmine::CustomFieldFormat.map do |fields|
  Dir[File.dirname(__FILE__) + '/lib/easy_extensions/custom_fields/*.rb'].each {|file| require file }

  fields.register Redmine::CustomFieldFormat.new('string', :label => :label_string, :order => 1)
  fields.register Redmine::CustomFieldFormat.new('text', :label => :label_text, :order => 2)
  fields.register Redmine::CustomFieldFormat.new('int', :label => :label_integer, :order => 3)
  fields.register Redmine::CustomFieldFormat.new('float', :label => :label_float, :order => 4)
  fields.register EasyExtensions::CustomFields::AutoincrementCustomFieldFormat.new(:label => :label_autoincrement, :order => 5)
  fields.register EasyExtensions::CustomFields::AmountCustomFieldFormat.new(:label => :label_amount, :order => 6)
  fields.register Redmine::CustomFieldFormat.new('list', :label => :label_list, :order => 7)
  fields.register Redmine::CustomFieldFormat.new('date', :label => :label_date, :order => 8)
  fields.register EasyExtensions::CustomFields::DateTimeCustomFieldFormat.new(:label => :label_datetime_custom_field, :order => 9)
  fields.register Redmine::CustomFieldFormat.new('bool', :label => :label_boolean, :order => 10)
  fields.register EasyExtensions::CustomFields::EasyLookupCustomFieldFormat.new(:label => :label_easy_lookup, :order => 11)
  fields.register EasyExtensions::CustomFields::EasyRatingCustomFieldFormat.new(:label => :label_rating, :order => 12)

  fields.register Redmine::CustomFieldFormat.new('email', :label => :label_email, :order => 13)
  fields.register Redmine::CustomFieldFormat.new('easy_google_map_address', :label => :label_easy_google_maps_address, :order => 14)
  fields.register Redmine::CustomFieldFormat.new('url', :label => :label_url, :order => 16)
  fields.register Redmine::CustomFieldFormat.new('user', :only => %w(Issue TimeEntry Version Project), :edit_as => 'list',:order => 17)
  fields.register Redmine::CustomFieldFormat.new('version', :only => %w(Issue TimeEntry Version Project), :edit_as => 'list', :order => 18)
end

# List of queries displayed to user on review pages(etc. my_page, sidebar, ...)
EasyQuery.map do |query|
  query.register EasyIssueQuery
  query.register EasyProjectQuery
  query.register EasyUserQuery
  query.register EasyVersionQuery
  query.register EasyAttendanceQuery
  query.register EasyTimeEntryQuery
end

Loofah::HTML5::WhiteList::ALLOWED_PROTOCOLS.add 'data'

Redmine::Activity.map do |activity|
  activity.register :easy_attendances, {:default => false}
end

