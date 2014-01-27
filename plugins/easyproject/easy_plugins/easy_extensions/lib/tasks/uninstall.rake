namespace :easyproject do
  namespace :uninstall do

    desc <<-END_DESC
    Get user's last login on and return YYYY-MM-DD.

    Example:
      bundle exec rake easyproject:uninstall:all_plugins RAILS_ENV=production
    END_DESC

    task :all_plugins => :environment do
      puts ''
      
      Dir[File.join(EasyExtensions::PATH_TO_EASYPROJECT_ROOT, 'easy_plugins', '*')].sort.each do |plugin_path|
        next if plugin_path.blank?
        plugin = File.basename(plugin_path)
        
        next if ['easy_extensions', 'easy_xml_helper'].include?(plugin)

        print "Do you like to uninstall plugin #{plugin}? [y/N]"
        STDOUT.flush
        next unless STDIN.gets.match(/^y$/i)

        ENV['VERSION'] = '0'
        ENV['NAME'] = plugin

        Rake::Task['redmine:plugins:migrate'].reenable
        Rake::Task['redmine:plugins:migrate'].invoke

        FileUtils.rm_rf(plugin_path)
        FileUtils.rm_rf(File.join(Rails.root, 'public', 'plugin_assets', plugin))

        puts ''
        puts "Plugin #{plugin} uninstalled."
        puts ''
      end

    end

  end
end