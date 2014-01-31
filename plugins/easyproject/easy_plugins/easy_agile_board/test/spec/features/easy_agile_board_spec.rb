require File.expand_path('../../../../../easy_extensions/test/spec/spec_helper', __FILE__)

feature 'Easy Agile Board' do

  before(:each) do
    @user = FactoryGirl.create(:admin_user)
    logged_user(@user)
  end

  let(:project) { FactoryGirl.create(:project, number_of_members: 3, number_of_issues: 0) }
  let(:issues) { FactoryGirl.create_list(:issue, 5, project: project, assigned_to: nil) }
  let(:sprints) { FactoryGirl.create_list(:easy_sprint, 3, project: project) }

  scenario "display button on project page" do
    visit project_path(project)
    page.should have_css('a.button-1', text: 'Agile board')
  end

  scenario "display project team and project backlog" do
    issues
    visit easy_agile_board_path(project)
    page.should have_css('h3', text: 'Project team')
    project.users.each do |u|
      page.should have_css('.project-team .member', text: u.name)
    end
    issues.each do |i|
      page.should have_css('.project-backlog li', text: i.to_s)
    end
  end

  scenario "display existing sprints", js: true do
    sprints
    visit easy_agile_board_path(project)
    page.should have_css('div.easy-sprint', count: 3)
  end

  scenario "create new sprint", js: true do
    visit easy_agile_board_path(project)
    page.should have_css('.agile-board-body form.easy-sprint', count: 1)
    click_button 'Create sprint'
    page.should have_css('#errorExplanation', text: "Name can't be blank")
    fill_in 'easy_sprint_name', with: 'Some new sprint'
    click_button 'Create sprint'
    page.should have_css('div.easy-sprint > h3', text: 'Some new sprint')
  end

  scenario "drag issue from project backlog to sprint backlog", js: true do
    issues; sprints;
    visit easy_agile_board_path(project)
    issue = page.find('.project-backlog li:first-child')
    issue_text = issue.text
    sprint_backlog = page.find('.easy-sprint:nth-child(2) .agile-list.backlog')
    issue.drag_to(sprint_backlog)
    visit current_path
    page.should have_css('.easy-sprint:nth-child(2) .agile-list.backlog li', count: 1, text: issue_text)
  end

  scenario "drag and drop issue assignment", js: true do
    issues; sprints;
    user = project.users.first
    issue = issues.last
    IssueEasySprintRelation.create(issue: issue, easy_sprint: sprints.last, relation_type: :backlog)

    visit easy_agile_board_path(project)
    page.find('h3', text: 'Project team').click
    sleep 2
    member_item = page.find(".project-team .member", text: user.name)
    issue_item = page.find(".agile-issue-item", text: issue.subject)
    member_item.drag_to(issue_item)
    issue_item.should have_css("img[alt=\"#{user.name}\"]")

    visit current_path
    page.should have_css(".agile-issue-item img[alt=\"#{user.name}\"]")
  end

end
