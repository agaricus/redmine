class EasyPluginGenerator < Rails::Generators::NamedBase
  source_root File.expand_path('../templates', __FILE__)

  attr_reader :plugin_path, :plugin_name_underscored, :plugin_pretty_name, :plugin_title

  def initialize(*args)
    super
    @plugin_name_underscored = file_name.underscore
    @plugin_pretty_name = plugin_name_underscored.titleize
    @plugin_path = "plugins/easyproject/easy_plugins/#{plugin_name_underscored}"
    @plugin_title = @plugin_name_underscored.camelize
  end

  def copy_templates
    empty_directory "#{plugin_path}/app"
    empty_directory "#{plugin_path}/app/controllers"
    empty_directory "#{plugin_path}/app/helpers"
    empty_directory "#{plugin_path}/app/models"
    empty_directory "#{plugin_path}/app/views"
    empty_directory "#{plugin_path}/db/migrate"
    empty_directory "#{plugin_path}/assets/images"
    empty_directory "#{plugin_path}/assets/javascripts"
    empty_directory "#{plugin_path}/assets/stylesheets"
    empty_directory "#{plugin_path}/config/locales"
    empty_directory "#{plugin_path}/lib/#{plugin_name_underscored}"
    empty_directory "#{plugin_path}/lib/#{plugin_name_underscored}/redmine/controllers"
    empty_directory "#{plugin_path}/lib/#{plugin_name_underscored}/redmine/helpers"
    empty_directory "#{plugin_path}/lib/#{plugin_name_underscored}/redmine/models"
    empty_directory "#{plugin_path}/lib/#{plugin_name_underscored}/redmine/others"

    template '.gitkeep', "#{plugin_path}/app/controllers/.gitkeep"
    template '.gitkeep', "#{plugin_path}/app/helpers/.gitkeep"
    template '.gitkeep', "#{plugin_path}/app/models/.gitkeep"
    template '.gitkeep', "#{plugin_path}/app/views/.gitkeep"
    template '.gitkeep', "#{plugin_path}/db/migrate/.gitkeep"
    template '.gitkeep', "#{plugin_path}/assets/images/.gitkeep"
    template '.gitkeep', "#{plugin_path}/assets/javascripts/.gitkeep"
    template '.gitkeep', "#{plugin_path}/lib/#{plugin_name_underscored}/redmine/others/.gitkeep"

    template 'init.rb.erb', "#{plugin_path}/init.rb"
    template 'after_init.rb.erb', "#{plugin_path}/after_init.rb"
    template 'after_activation.rb.erb', "#{plugin_path}/after_activation.rb"
    template 'after_deactivation.rb.erb', "#{plugin_path}/after_deactivation.rb"
    template 'cs.yml', "#{plugin_path}/config/locales/cs.yml"
    template 'en.yml', "#{plugin_path}/config/locales/en.yml"
    template 'routes.rb.erb', "#{plugin_path}/config/routes.rb"
    template 'hooks.rb.erb', "#{plugin_path}/lib/#{plugin_name_underscored}/hooks.rb"
    template 'issue_patch.example.erb', "#{plugin_path}/lib/#{plugin_name_underscored}/redmine/models/issue_patch.example"
    template 'issues_controller_patch.example.erb', "#{plugin_path}/lib/#{plugin_name_underscored}/redmine/controllers/issues_controller_patch.example"
    template 'issues_helper_patch.example.erb', "#{plugin_path}/lib/#{plugin_name_underscored}/redmine/helpers/issues_helper_patch.example"
  end

end
