class AddDefaultPageTemplates3 < ActiveRecord::Migration
  def self.up
    EasyPageTemplateModule.reset_column_information
    EasyPageZoneModule.reset_column_information
    EasyPage.reset_column_information
    EasyPageTemplate.reset_column_information

    my_page = EasyPage.find_by_page_name('my-page')
    my_page_template = EasyPageTemplate.default_template_for_page(my_page)

    unless my_page_template
      my_page_template = EasyPageTemplate.create(:easy_pages_id => my_page.id, :template_name => 'Default template', :description => 'Default template', :is_default => true)

      EasyPageTemplateModule.create_template_module(my_page, my_page_template, EpmIssuesAssignedToMe.first, 'middle-left', HashWithIndifferentAccess.new('row_limit' => '10'), 1)
      EasyPageTemplateModule.create_template_module(my_page, my_page_template, EpmIssuesReportedByMe.first, 'middle-left', HashWithIndifferentAccess.new('row_limit' => '10'), 2)
      EasyPageTemplateModule.create_template_module(my_page, my_page_template, EpmIssuesWatchedByMe.first, 'middle-left', HashWithIndifferentAccess.new('row_limit' => '10'), 3)
      EasyPageTemplateModule.create_template_module(my_page, my_page_template, EpmSavedQueries.first, 'middle-right', HashWithIndifferentAccess.new, 1)
      EasyPageTemplateModule.create_template_module(my_page, my_page_template, EpmMyProjectsSimple.first, 'middle-right', HashWithIndifferentAccess.new, 2)
    end

    project_overview = EasyPage.find_by_page_name('project-overview')
    project_overview_template = EasyPageTemplate.default_template_for_page(project_overview)

    unless project_overview_template
      project_overview_template = EasyPageTemplate.create(:easy_pages_id => project_overview.id, :template_name => 'Default template', :description => 'Default template', :is_default => true)

      EasyPageTemplateModule.create_template_module(project_overview, project_overview_template, EpmProjectSidebarProjectInfo.first, 'right-sidebar', HashWithIndifferentAccess.new, 1)
      EasyPageTemplateModule.create_template_module(project_overview, project_overview_template, EpmProjectSidebarFamilyInfo.first, 'right-sidebar', HashWithIndifferentAccess.new, 2)
      EasyPageTemplateModule.create_template_module(project_overview, project_overview_template, EpmProjectSidebarProjectMembers.first, 'right-sidebar', HashWithIndifferentAccess.new, 3)
      EasyPageTemplateModule.create_template_module(project_overview, project_overview_template, EpmProjectNews.first, 'top-left', HashWithIndifferentAccess.new, 1)
      EasyPageTemplateModule.create_template_module(project_overview, project_overview_template, EpmProjectIssues.first, 'top-left', HashWithIndifferentAccess.new, 2)
    end

  end

  def self.down
  end

end
