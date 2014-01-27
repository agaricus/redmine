module EasyPatch
  module ThemesPatch

    def self.included(base)
      base.extend(ClassMethods)

      base.class_eval do
        
        class << self

          alias_method_chain :scan_themes, :easy_extensions
          
        end

      end

    end

    module ClassMethods

      def scan_themes_with_easy_extensions
        dirs = Dir.glob("#{Rails.public_path}/plugin_assets/easy_extensions/themes/*").select do |f|
          # A theme should at least override application.css
          File.directory?(f) && File.exist?("#{f}/stylesheets/application.css")
        end
        scans = []
        dirs.each do |dir| 
          t = Redmine::Themes::Theme.new(dir)
          t.easy_theme = true
          scans << t 
        end
        
        (scans + scan_themes_without_easy_extensions).sort
      end
    end

  end
  
  module ThemePatch
    def self.included(base)
      base.send(:include, InstanceMethods)

      base.class_eval do

        attr_accessor :easy_theme

        alias_method_chain :stylesheet_path, :easy_extensions
        alias_method_chain :javascript_path, :easy_extensions
        alias_method_chain :image_path, :easy_extensions

        def theme_public_path
          return self.path.gsub(/^#{Regexp.escape(Rails.public_path)}/, '')
        end

        def is_easy_theme?
          return !@easy_theme.nil?
        end

      end

    end

    module InstanceMethods

      def stylesheet_path_with_easy_extensions(source)
        "#{theme_public_path}/stylesheets/#{source}"
      end

      def javascript_path_with_easy_extensions(source)
        "#{theme_public_path}/javascripts/#{source}"
      end
      def image_path_with_easy_extensions(source)
        "#{theme_public_path}/images/#{source}"
      end
    end
  end
  
end
EasyExtensions::PatchManager.register_other_patch 'Redmine::Themes', 'EasyPatch::ThemesPatch'
EasyExtensions::PatchManager.register_other_patch 'Redmine::Themes::Theme', 'EasyPatch::ThemePatch'
