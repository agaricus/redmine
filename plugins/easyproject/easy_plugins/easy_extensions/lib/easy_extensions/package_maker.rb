require 'utils/shell_utils'
module EasyExtensions
  class PackageMaker

    SUPPORTED_ZIP = [:'7za', :zip]
    TMP_FOLDER = File.join(Rails.root, 'tmp', 'package')
    TMP_FOLDER_PLUGINS = File.join(TMP_FOLDER, 'plugins')
    TMP_FOLDER_SQL = File.join(TMP_FOLDER, 'sql')
    TMP_FOLDER_EASYPROJECT = File.join(TMP_FOLDER_PLUGINS, 'easyproject')
    TMP_FOLDER_EASYPLUGINS = File.join(TMP_FOLDER_EASYPROJECT, 'easy_plugins')

    attr_reader :errors, :messages

    def initialize(plugins=[])
      pl = Array.wrap(plugins)
      pl << :easy_extensions unless pl.include?(:easy_extensions)

      @plugins_to_package = self.class.all_plugins.select{|p| pl.include?(p.id)}
      @errors = []
      @messages = ''
    end

    def self.all_plugins
      return @all_plugins if @all_plugins

      @all_plugins = Redmine::Plugin.all(:without_disabled => true).select{|p| !p.directory.match(/easyproject\/easy_helpers/)}
      @all_plugins.reject!{|p| [:easy_exceptions_server, :easy_redmine, :easy_xml_helper].include?(p.id) }

      @all_plugins
    end

    def self.support_zip_7za?
      begin
        EasyUtils::ShellUtils.shellout('7za'){ |io| io.read }.to_s
        return true
      rescue EasyUtils::ShellUtils::CommandFailed => ex
        return false
      end
    end

    def self.support_zip_zip?
      begin
        EasyUtils::ShellUtils.shellout('zip'){ |io| io.read }.to_s
        return true
      rescue EasyUtils::ShellUtils::CommandFailed => ex
        return false
      end
    end

    def self.create_zip_package_by_7za(package_name)
      cmd = "7za a \"#{File.join(TMP_FOLDER, package_name)}\" \"#{File.join(TMP_FOLDER, '*')}\""
      @messages = EasyUtils::ShellUtils.shellout(cmd){ |io| io.read }.to_s
    end

    def self.create_zip_package_by_zip(package_name)
      cmd = "cd #{TMP_FOLDER} && zip -r #{package_name} *"
      @messages = EasyUtils::ShellUtils.shellout(cmd){ |io| io.read }.to_s
    end

    def self.create_mysql_dump(username, password, host, database)
      cmd = "mysqldump --opt -u#{username} -p#{password} -h#{host} #{database} > \"#{File.join(TMP_FOLDER_SQL, 'database.sql')}\""
      @messages = EasyUtils::ShellUtils.shellout(cmd){ |io| io.read }.to_s
    end

    def self.transform_plugin_names(plugin_names)
      plugin_names.collect{|p| transform_plugin_name(p)}
    end

    def self.transform_plugin_name(plugin_name)
      case plugin_name.to_s.strip.downcase
      when 'Agile Board'.downcase
        :easy_agile_board
      when 'Alerts'.downcase
        :easy_alerts
      when 'Attachments'.downcase
        :easy_project_attachments
      when 'Attendance'.downcase
        :easy_attendances
      when 'Basecamp Import'.downcase
        :easy_basecamp_import
      when 'Budget'.downcase
        :easy_money
      when 'Budget Sheet'.downcase
        :easy_budgetsheet
      when 'Cash Desk'.downcase
        :easy_cash_desks
      when 'Computed custom fields'.downcase
        :easy_computed_custom_fields
      when 'Contacts'.downcase
        :easy_contacts
      when 'Cost Estimation'.downcase
        :easy_calculation
      when 'Evernote Sync'.downcase
        :easy_evernote_integration
      when 'External storages'.downcase
        :easy_external_storages
      when 'Help Desk'.downcase
        :easy_helpdesk
      when 'Instant Messaging'.downcase
        :easy_instant_messages
      when 'Knowledge base'.downcase
        :easy_knowledge
      when 'MS Project'.downcase
        :easy_data_templates
      when 'Personal Finances'.downcase
        :easy_personal_finances
      when 'Personal Time Management'.downcase
        :easy_calendar
      when 'Printable templates'.downcase
        :easy_printable_templates
      when 'Quick project planner'.downcase
        :easy_quick_project_planner
      when 'Reports'.downcase
        :easy_reports
      when 'Resources'.downcase
        :easy_user_allocations
      when 'ToDo'.downcase
        :easy_to_do_list
      end
    end

    def include_redmine?
      !!@include_redmine
    end

    def include_sql?
      !!@include_sql
    end

    def include_files?
      !!@include_files
    end

    def package_name
      @package_name ||= "package-#{Time.now.strftime('%Y%m%d%H%M')}.zip"
    end

    def create_package(options={})
      return false unless @errors.blank?

      @include_redmine = !!options.delete(:include_redmine)
      @include_sql = !!options.delete(:include_sql)
      @include_files = !!options.delete(:include_files)

      zip_method = SUPPORTED_ZIP.detect{|m| m.to_s == options[:zip_method].to_s}

      prepare_package

      return false unless @errors.blank?

      zip_folder(zip_method)

      return @errors.blank?
    end

    private

    def prepare_package
      return unless @errors.blank?

      begin
        create_required_folders_for_easyproject
      rescue Exception => ex
        @errors << ex.message
      end

      return unless @errors.blank?

      if include_redmine?
        copy_redmine
      end

      return unless @errors.blank?

      @plugins_to_package.each do |plugin|
        copy_plugin(plugin)
      end

      return unless @errors.blank?

      if include_sql?
        begin
          create_sql_dump
        rescue Exception => ex
          @errors << ex.message
        end
      end
    end

    def create_required_folders_for_easyproject
      if File.exist?(TMP_FOLDER)
        FileUtils.rm_rf(TMP_FOLDER)
      end

      unless File.exist?(TMP_FOLDER)
        FileUtils.mkdir(TMP_FOLDER)
      end

      unless File.exist?(TMP_FOLDER_PLUGINS)
        FileUtils.mkdir(TMP_FOLDER_PLUGINS)
      end

      unless File.exist?(TMP_FOLDER_EASYPROJECT)
        FileUtils.mkdir(TMP_FOLDER_EASYPROJECT)
      end

      if include_sql? && !File.exist?(TMP_FOLDER_SQL)
        FileUtils.mkdir(TMP_FOLDER_SQL)
      end

      Dir.foreach(EasyExtensions::PATH_TO_EASYPROJECT_ROOT) do |item|
        next if ['.', '..', 'easy_plugins'].include?(item)

        FileUtils.cp_r(File.join(EasyExtensions::PATH_TO_EASYPROJECT_ROOT, item), TMP_FOLDER_EASYPROJECT)
      end

      unless File.exist?(TMP_FOLDER_EASYPLUGINS)
        FileUtils.mkdir(TMP_FOLDER_EASYPLUGINS)
      end
    end

    def copy_redmine
      Dir.foreach(Rails.root) do |item|
        next if ['.', '..', '.git', 'files', 'log', 'nbproject', 'plugins', 'public', 'tmp'].include?(item)

        FileUtils.cp_r(File.join(Rails.root, item), TMP_FOLDER)
      end

      if include_files?
        FileUtils.cp_r(File.join(Rails.root, 'files'), TMP_FOLDER)
      end

      [
        'files', 'log', 'public', 'test', 'tmp', File.join('tmp', 'cache'), File.join('tmp', 'pdf'),
        File.join('tmp', 'pids'), File.join('tmp', 'sessions'), File.join('tmp', 'sockets'),
        File.join('tmp', 'test'), File.join('tmp', 'thumbnails')
      ].each do |item|
        unless File.exist?(File.join(TMP_FOLDER, item))
          begin
            FileUtils.mkdir(File.join(TMP_FOLDER, item))
          rescue
          end
        end
      end

      Dir.foreach(File.join(Rails.root, 'public')) do |item|
        next if ['.', '..', 'plugin_assets'].include?(item)

        FileUtils.cp_r(File.join(Rails.root, 'public', item), File.join(TMP_FOLDER, 'public'))
      end

      [
        'Gemfile.local',
        File.join('config', 'database.yml'), File.join('config', 'configuration.yml'),
        File.join('config', 'initializers', '22-change_plugins_order.rb'), File.join('config', 'initializers', 'secret_token.rb'),
        File.join('config', 'initializers', 'pdfkit.rb')
      ].each do |item|
        FileUtils.rm(File.join(TMP_FOLDER, item)) if File.exist?(File.join(TMP_FOLDER, item))
      end
    end

    def copy_plugin(plugin)
      return if plugin.nil?

      folders = get_folders_for_plugin(plugin)

      folders.each do |folder|
        full_folder_path = File.join(EasyExtensions::EASYPROJECT_EASY_PLUGINS_DIR, folder)
        next unless File.exist?(full_folder_path)

        FileUtils.cp_r(full_folder_path, TMP_FOLDER_EASYPLUGINS)
      end
    end

    def get_folders_for_plugin(plugin)
      folders = []
      folders << plugin.id.to_s

      case plugin.id
      when :easy_budgetsheet
        folders << 'easy_money'
      when :easy_data_templates
        folders << 'easy_xml_helper'
      when :easy_extensions
        folders << 'easy_redmine'
        folders << 'easy_xml_helper'
      when :easy_helpdesk
        folders << 'easy_alerts'
      when :easy_money
        folders << 'easy_budgetsheet'
      end

      folders
    end

    def zip_folder(zip_method=nil)
      zip_method ||= :zip

      m = "support_zip_#{zip_method}?"
      zip_supported = self.class.send(m) if self.class.respond_to?(m)

      unless zip_supported
        @errors << "#{zip_method} command not found!"
        return nil
      end

      m = "create_zip_package_by_#{zip_method}"
      if self.class.respond_to?(m)
        ret = self.class.send(m, package_name)
        return ret
      else
        @errors << "Cannot find method (#{m}) for creating package."
        return nil
      end
    end

    def create_sql_dump
      config = ActiveRecord::Base.configurations['production']

      unless config
        @errors << 'Unknown or missing database configuration.'
        return
      end

      unless ['mysql', 'mysql2'].include?(config['adapter'])
        @errors << 'Only MySQL dump is supported.'
        return
      end

      self.class.create_mysql_dump(config['username'], config['password'], config['host'], config['database'])
    end

  end
end
