class EnsureAllPageModules < ActiveRecord::Migration

  def self.up
    EasyPage.reset_column_information
    EasyPageZone.reset_column_information
    EasyPageAvailableZone.reset_column_information
    EasyPageAvailableModule.reset_column_information

    EpmAttendance.install_to_page('my-page')
    EpmDocuments.install_to_page('my-page')
    EpmIssueQuery.install_to_page('my-page')
    EpmIssuesAssignedToMe.install_to_page('my-page')
    EpmIssuesCreateNew.install_to_page('my-page')
    EpmIssuesReportedByMe.install_to_page('my-page')
    EpmIssuesWatchedByMe.install_to_page('my-page')
    EpmMyCalendar.install_to_page('my-page')
    EpmMyProjectsSimple.install_to_page('my-page')
    EpmNews.install_to_page('my-page')
    EpmNoticeboard.install_to_page('my-page')
    EpmProjectsQuery.install_to_page('my-page')
    EpmSavedQueries.install_to_page('my-page')
    EpmTimelogCalendar.install_to_page('my-page')
    EpmTimelogSimple.install_to_page('my-page')

    EpmGoogleMaps.install_to_page('project-overview')
    EpmIssuesCreateNew.install_to_page('project-overview')
    EpmIssueQuery.install_to_page('project-overview')
    EpmNoticeboard.install_to_page('project-overview')
    EpmProjectInfo.install_to_page('project-overview')
    EpmProjectIssues.install_to_page('project-overview')
    EpmProjectNews.install_to_page('project-overview')
    EpmProjectSidebarAllUsersQueries.install_to_page('project-overview')
    EpmProjectSidebarFamilyInfo.install_to_page('project-overview')
    EpmProjectSidebarProjectInfo.install_to_page('project-overview')
    EpmProjectSidebarProjectMembers.install_to_page('project-overview')
    EpmProjectSidebarSavedQueries.install_to_page('project-overview')
    EpmProjectTree.install_to_page('project-overview')
    EpmProjectsQuery.install_to_page('project-overview')
    EpmResourceAvailability.install_to_page('project-overview')
    EpmUsersQuery.install_to_page('project-overview')
  end

  def self.down
    EpmAttendance.destroy_all
    EpmDocuments.destroy_all
    EpmIssueQuery.destroy_all
    EpmIssuesAssignedToMe.destroy_all
    EpmIssuesCreateNew.destroy_all
    EpmIssuesReportedByMe.destroy_all
    EpmIssuesWatchedByMe.destroy_all
    EpmMyCalendar.destroy_all
    EpmMyProjectsSimple.destroy_all
    EpmNews.destroy_all
    EpmNoticeboard.destroy_all
    EpmProjectsQuery.destroy_all
    EpmSavedQueries.destroy_all
    EpmTimelogCalendar.destroy_all
    EpmTimelogSimple.destroy_all

    EpmGoogleMaps.destroy_all
    EpmProjectInfo.destroy_all
    EpmProjectIssues.destroy_all
    EpmProjectNews.destroy_all
    EpmProjectSidebarAllUsersQueries.destroy_all
    EpmProjectSidebarFamilyInfo.destroy_all
    EpmProjectSidebarProjectInfo.destroy_all
    EpmProjectSidebarProjectMembers.destroy_all
    EpmProjectSidebarSavedQueries.destroy_all
    EpmProjectTree.destroy_all
    EpmResourceAvailability.destroy_all
    EpmUsersQuery.destroy_all
  end

end
