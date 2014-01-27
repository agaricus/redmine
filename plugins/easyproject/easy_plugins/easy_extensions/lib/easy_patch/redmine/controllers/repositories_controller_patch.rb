module EasyPatch
  module RepositoriesControllerPatch

    def self.included(base)
      base.send(:include, InstanceMethods)

      base.class_eval do

        include EasySettingHelper

        before_filter :repo_save_easy_settings, :only => [:create, :update]
        before_filter :create_repo_from_url, :only => [:create]

        def repo_save_easy_settings
          save_easy_settings(@project)
        end

        def create_repo_from_url
          return if params[:easy_repository_source] != 'easy_repository_url' || params[:repository].blank? || params[:repository][:easy_repository_url].blank?
          repo_url = params[:repository][:easy_repository_url]

          repo_container_dir = File.join(Rails.root, EasySetting.value('git_repository_path'))

          begin
            FileUtils.mkdir(repo_container_dir) unless File.exist?(repo_container_dir)
          rescue Exception => ex
            flash[:error] = ex.message
          end

          unless File.exist?(repo_container_dir)
            flash[:error] = l(:error_create_repo_from_url_cannot_create_dir, :dir => repo_container_dir)
            return
          end

          if m = repo_url.match(/^\S*\/(\S+.git)$/)
            repo_name = m[1]
          elsif m = repo_url.match(/^\S*\/(\S+.)$/)
            repo_name = m[1]
          end

          if repo_name.blank?
            flash[:error] = l(:error_create_repo_from_url_cannot_determine_repo_name)
            return
          end

          repo_created = false
          repository_url = File.join(repo_container_dir, repo_name)

          if File.exist?(repository_url)
            flash[:error] = l(:error_create_repo_from_url_repo_already_exists)
            return
          end

          Dir.chdir(repo_container_dir){repo_created = system("git clone --mirror \"#{repo_url}\"")}

          if repo_created
            if m = repository_url.match(/^\S*\/(\S+.git)$/)
              params[:repository]['url'] = repository_url
            else
              params[:repository]['url'] = repository_url + '.git'
            end
          else
            flash[:error] = (l(:error_create_repo_from_url_repo_cannot_be_created) + '<br />' + "git clone --mirror \"#{repo_url}\"").html_safe
          end

        end

      end
    end

    module InstanceMethods

    end

  end
end
EasyExtensions::PatchManager.register_controller_patch 'RepositoriesController', 'EasyPatch::RepositoriesControllerPatch'
