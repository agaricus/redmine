module EasyExtensions

  @@domain_name, @@version, @@additional_installer_rake_tasks = nil, nil, []

  mattr_accessor :debug_mode
  self.debug_mode = false

  EASY_HELPERS_DIR = 'easy_helpers'
  EASY_PLUGINS_DIR = 'easy_plugins'
  RELATIVE_EASYPROJECT_PLUGIN_PATH = File.join('plugins', 'easyproject')
  RELATIVE_EASYPROJECT_EASY_PLUGINS_PATH = File.join(RELATIVE_EASYPROJECT_PLUGIN_PATH, EASY_PLUGINS_DIR)
  PATH_TO_EASYPROJECT_ROOT = File.join(Rails.root, RELATIVE_EASYPROJECT_PLUGIN_PATH)

  EASYPROJECT_EASY_PLUGINS_DIR = File.join(Rails.root, RELATIVE_EASYPROJECT_EASY_PLUGINS_PATH)
  EASY_EXTENSIONS_DIR = File.join(EASYPROJECT_EASY_PLUGINS_DIR, 'easy_extensions')

  SUPPORTED_LANGS = [:cs, :da, :de, :en, :es, :fi, :fr, :hu, :it, :ja, :'pt-BR', :pt, :sv, :ru, :'zh-TW', :zh]

  REDMINE_CUSTOM_FIELDS = ['DocumentCategoryCustomField', 'GroupCustomField', 'IssueCustomField', 'IssuePriorityCustomField', 'ProjectCustomField',
    'TimeEntryActivityCustomField', 'TimeEntryCustomField', 'UserCustomField', 'VersionCustomField']

  def self.domain_name
    @@domain_name ||= begin; (Rails.root.to_s.split(/[\\\/]/) - ['public_html']).last; rescue; 'nodomain'; end
  end

  def self.version
    unless @@version
      ep_site_version = nil
      version_path = File.join(Rails.root, 'version')
      File.open(version_path, 'r') do |f|
        begin
          ep_site_version = f.readline
        rescue
        end
      end if File.exists?(version_path)
      @@version = ep_site_version || 'not_detected'
    end
    @@version
  end

  def self.render_sidebar?(controller_name, action_name, params)
    val = EasyProjectSettings.disabled_sidebar[controller_name]
    if val.is_a?(Hash)
      if (val.has_key?(action_name))
        ca_val = val[action_name]
        if (ca_val.is_a?(String))
          return false
        elsif (ca_val.is_a?(Hash))
          ca_val.each do |k, v|
            unless (params[k].nil?)
              return false if params[k] == v
            end
          end
        end
      end
    elsif val.is_a?(Array)
      return false if val.include?(action_name)
    end if (val)

    return true
  end

  def self.easy_searchable_column_types
    @@easy_searchable_column_types ||= ['name', 'description', 'comment', 'other']
  end

  def self.register_additional_installer_tasks(task_name)
    @@additional_installer_rake_tasks ||= []
    @@additional_installer_rake_tasks << task_name unless @@additional_installer_rake_tasks.include?(task_name)
  end

  def self.additional_installer_rake_tasks
    @@additional_installer_rake_tasks || []
  end

  module EasyProjectSettings

    mattr_accessor :disabled_sidebar
    self.disabled_sidebar = {'calendars' => ['show'], 'users' => {'edit' => {'tab' => 'my_page'}}}

    mattr_accessor :disabled_features
    self.disabled_features = {
      :modules => ['boards', 'files', 'wiki', 'wiki_edits', 'messages', 'user_allocations', 'repository', 'easy_other_permissions', 'easy_attendances'],
      :permissions => {'boards' => :all, 'files' => :all, 'wiki' => :all, 'wiki_edits' => :all, 'messages' => :all, 'easy_attendances' => :all},
      :notifiables => ['wiki_content_added', 'wiki_content_updated', 'file_added', 'message_posted'],
      :search_types => ['wiki_pages', 'messages'],
      :administration_setings_tabs => ['repositories'],
      :others => []
    }

    mattr_accessor :easy_color_schemes_count
    self.easy_color_schemes_count = 7

    mattr_accessor :easy_attendance_enabled
    self.easy_attendance_enabled = false

    mattr_accessor :app_name
    self.app_name = 'Easy Project'
    
    mattr_accessor :app_link
    self.app_link = 'www.easyproject.cz'

    mattr_accessor :app_email
    self.app_email = 'podpora@easyproject.cz'

    mattr_accessor :enable_copying_files_on_restart
    self.enable_copying_files_on_restart = true

  end

end
