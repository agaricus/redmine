require 'redmine/plugin'
module Redmine
  class Plugin

    def self.load
      Dir.glob(File.join(self.directory, '*')).sort_by{|p| (p.ends_with?('/easyproject') ? '0-' : '1-') + p}.each do |directory|
        if File.directory?(directory)
          lib = File.join(directory, "lib")
          if File.directory?(lib)
            $:.unshift lib
            ActiveSupport::Dependencies.autoload_paths += [lib]
          end
          initializer = File.join(directory, "init.rb")
          if File.file?(initializer)
            require initializer
          end
        end
      end
    end

    def self.mirror_assets(name=nil)
      if name.present?
        find(name).mirror_assets
      else
        begin
          if File.exist?(Redmine::Plugin.public_directory)
            FileUtils.rm_r(Redmine::Plugin.public_directory)
          end
        rescue Exception => e
          puts "Could not delete plugin assets: " + e.message
        end
        all.each do |plugin|
          plugin.mirror_assets
        end
      end
    end

  end
end
