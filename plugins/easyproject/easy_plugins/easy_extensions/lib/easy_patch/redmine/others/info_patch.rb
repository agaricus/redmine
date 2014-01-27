module EasyPatch
  module RedmineInfoPatch

    def self.included(base)

      base.class_eval do

        class << self

          def app_name_with_easy_extensions; EasyExtensions::EasyProjectSettings.app_name; end
          def url_with_easy_extensions; EasyExtensions::EasyProjectSettings.app_link; end
          def help_url_with_easy_extensions; '' end

          alias_method_chain :app_name, :easy_extensions
          alias_method_chain :url, :easy_extensions
          alias_method_chain :help_url, :easy_extensions
        end
      end
    end

  end
end
EasyExtensions::PatchManager.register_other_patch 'Redmine::Info', 'EasyPatch::RedmineInfoPatch'
