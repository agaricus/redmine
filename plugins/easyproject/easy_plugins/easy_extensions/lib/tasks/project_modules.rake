namespace :easyproject do
  namespace :project_modules do

    desc <<-END_DESC
    Enasble project module.

    Example:
      bundle exec rake easyproject:project_modules:enable module=easy_money project=5
    END_DESC

    task :enable => :environment do
      projects = (ENV['project'].blank? ? Project.non_templates : Project.find_by_id(ENV['project']).self_and_descendants.non_templates)
      projects.each do |project|
        project.enabled_module_names = ((project.enabled_module_names || []) + [ENV['module']]) unless project.enabled_module_names.include?(ENV['module'])
        puts "#{project.family_name}:#{project.enabled_module_names.include?(ENV['module'])}-[#{project.enabled_module_names.join(', ')}]"
      end
    end
  end
end