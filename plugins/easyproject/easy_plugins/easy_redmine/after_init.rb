EasyExtensions::EasyProjectSettings.disabled_features[:modules].delete_if{|x| ['boards', 'files', 'wiki', 'wiki_edits', 'messages', 'repository'].include?(x)}
EasyExtensions::EasyProjectSettings.disabled_features[:permissions].delete_if{|x, v| ['boards', 'files', 'wiki', 'wiki_edits', 'messages', 'repository'].include?(x)}
EasyExtensions::EasyProjectSettings.disabled_features[:notifiables].delete_if{|x| ['wiki_content_added', 'wiki_content_updated', 'file_added', 'message_posted'].include?(x)}
EasyExtensions::EasyProjectSettings.disabled_features[:search_types].delete_if{|x| ['wiki_pages', 'messages'].include?(x)}
EasyExtensions::EasyProjectSettings.disabled_features[:administration_setings_tabs].delete_if{|x| ['repositories'].include?(x)}
EasyExtensions::EasyProjectSettings.app_email = 'support@easyredmine.com'

if EasyExtensions::EasyProjectSettings.enable_copying_files_on_restart
  begin
    FileUtils.cp("#{EasyExtensions::PATH_TO_EASYPROJECT_ROOT}/easy_plugins/easy_redmine/lib/easy_redmine/to_copy/404.html", "#{Rails.root}/public/404.html")
    FileUtils.cp("#{EasyExtensions::PATH_TO_EASYPROJECT_ROOT}/easy_plugins/easy_redmine/lib/easy_redmine/to_copy/500.html", "#{Rails.root}/public/500.html")
  rescue
  end
end

ActionDispatch::Reloader.to_prepare do

  require 'easy_redmine/hooks'

end

EasyExtensions::EasyProjectSettings.app_name = 'Easy Redmine'
EasyExtensions::EasyProjectSettings.app_link = 'www.easyredmine.com'