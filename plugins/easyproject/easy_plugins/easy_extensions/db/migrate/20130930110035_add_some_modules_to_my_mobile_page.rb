class AddSomeModulesToMyMobilePage < ActiveRecord::Migration
  def up
    EpmMobileIssuesAssignedToMe.install_to_page('my-mobile-page')
    EpmMyProjectsSimple.install_to_page('my-mobile-page')
  end
  def down
    EpmMobileIssuesAssignedToMe.destroy_all
  end
end
