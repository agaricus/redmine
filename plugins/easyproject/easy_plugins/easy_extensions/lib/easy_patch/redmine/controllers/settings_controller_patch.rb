module EasyPatch
  module SettingsControllerPatch

    def self.included(base)
      base.extend(ClassMethods)
      base.send(:include, InstanceMethods)

      base.class_eval do

        before_render :settings_before_render, :except => :plugin

        include EasySettingHelper

        alias_method_chain :edit, :easy_extensions

        def uninstall
          lock_file = File.join(Rails.root, 'tmp', 'plugin_uninstalling.txt')

          if File.exist?(lock_file)
            flash[:error] = 'Cannot continue due to running previous uninstalling.'
            redirect_to :controller => 'admin', :action => 'plugins'
            return
          else
            File.open(lock_file, 'w') do |f|
            end
          end

          plugin = Redmine::Plugin.find(params[:id])
          plugin_dir = Dir.new(EasyExtensions::PATH_TO_EASYPROJECT_ROOT+'/easy_plugins')
          plugin_name = l(plugin.name)

          #disabling module for all projects
          EnabledModule.where(:name => plugin.id.to_s).delete_all

          system "bundle exec rake redmine:plugins:migrate NAME=#{plugin.id.to_s} VERSION=0 RAILS_ENV=production"

          #delete directories
          directory = plugin_dir.select{|dir| dir == plugin.id.to_s}.first
          unless directory.blank?
            FileUtils.rm_rf(plugin_dir.path+'/'+directory)
            FileUtils.rm_rf(Rails.root+'/public/plugin_assets/'+directory)
          end

          #delete plugin from registed_plugins
          #Redmine::Plugin.registered_plugins.delete(plugin.id)
          begin
            system "touch #{File.join(Rails.root, 'tmp', 'restart.txt')}"
          rescue
          end

          FileUtils.rm lock_file

          flash[:notice] = l(:notice_plugin_successful_uninstall, :plugin => plugin_name)
          redirect_to :controller => 'admin', :action => 'plugins'
        end

        def release_cache
          Rails.cache.clear

          render :nothing => true
        end

      end
    end

    module InstanceMethods

      def settings_before_render
        @notifiables = @notifiables.delete_if { |i| EasyExtensions::EasyProjectSettings.disabled_features[:notifiables].include?(i.to_s)} unless @notifiables.blank?
      end

      def edit_with_easy_extensions
        save_easy_settings(nil) if request.post?
        edit_without_easy_extensions
      end
    end

    module ClassMethods
    end

  end
end
EasyExtensions::PatchManager.register_controller_patch 'SettingsController', 'EasyPatch::SettingsControllerPatch'
