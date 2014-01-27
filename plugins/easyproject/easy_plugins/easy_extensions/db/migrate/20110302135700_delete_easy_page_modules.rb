class DeleteEasyPageModules < ActiveRecord::Migration
  def self.up
    EasyPageModule.reset_column_information

    mod1 = EasyPageModule.find_by_module_name('root_project_news')
    mod1.destroy if mod1

    mod2 = EasyPageModule.find_by_module_name('root_project_tree')
    mod2.destroy if mod2

    mod3 = EasyPageModule.find_by_module_name('project_sidebar_root_project_info')
    mod3.destroy if mod3

    mod4 = EasyPageModule.find_by_module_name('project_sidebar_root_project_members')
    mod4.destroy if mod4

    mod5 = EasyPageModule.find_by_module_name('root_project_issues')
    mod5.destroy if mod5
  end

  def self.down
  end
end
