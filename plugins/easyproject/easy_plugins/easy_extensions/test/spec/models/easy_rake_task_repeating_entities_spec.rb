
describe EasyRakeTaskRepeatingEntities do

  it 'create issue to be repeated with righ params' do
    author = FactoryGirl.create(:user, :lastname => 'Author')
    assigned_to = FactoryGirl.create(:user, :lastname => 'Assignee')
    issue = FactoryGirl.create(:issue, :reccuring, :author => author, :assigned_to => assigned_to)
    rake_task = EasyRakeTaskRepeatingEntities.new(:active => true, :settings => {}, :period => :daily, :interval => 1, :next_run_at => Time.now)
    $stdout.stubs(:puts)
    expect{ rake_task.execute }.to change(Issue,:count).by(1)

    issue.reload

    issue.relations_from.count.should == 1
    issue_to = issue.relations_from.first.issue_to
    
    issue_to.author.should == author
    issue_to.assigned_to.should == assigned_to
  end

  it 'set right repeat date, when created' do
    issue = FactoryGirl.create(:issue, :reccuring_monthly)
    repeat_day = issue.easy_repeat_settings['monthly_day'].to_i
    issue.easy_next_start.should == (Date.today + repeat_day.days - Date.today.mday.days)
  end

end