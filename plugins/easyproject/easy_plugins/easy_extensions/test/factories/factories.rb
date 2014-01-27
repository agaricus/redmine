FactoryGirl.define do
  sequence :subject do |n|
    "Test issue #{n}"
  end

  factory :project do
    ignore do
      number_of_issues 2
      number_of_members 0
    end
    name 'Test project'

    after(:create) do |project|
      trackers = Tracker.all
      trackers = [FactoryGirl.create(:tracker), FactoryGirl.create(:bug_tracker)] unless trackers.any?
      project.trackers = trackers
      project.time_entry_activities = [FactoryGirl.create(:time_entry_activity)]
    end
    after :create do |project, evaluator|
      FactoryGirl.create_list :issue, evaluator.number_of_issues, :project => project
      FactoryGirl.create_list :member, evaluator.number_of_members, :project => project, :roles => [FactoryGirl.create(:role)]
    end
  end

  factory :project_custom_field do
    sequence(:name) { |n| "Project CF ##{n}" }
    field_format 'string'
    is_for_all true
  end

  factory :role do
    sequence(:name){ |n| "Role ##{n}" }
    permissions Role.new.setable_permissions.collect(&:name).uniq
  end

  factory :member do
    association :project
    association :user
    association :roles
  end

  factory :tracker do
    sequence(:name) {|n| "Feature ##{n}"}

    trait :bug do
      name 'Bug'
    end

    factory :bug_tracker, :traits => [:bug]
  end

  factory :enumeration do
    name 'TestEnum'

    trait :default do
      name 'Default'
      is_default true
    end
  end

  # not an enumeration, but same behaviour
  factory :issue_status, :parent => :enumeration, :class => 'IssueStatus' do
    name 'TestStatus'
  end

  factory :issue_priority, :parent => :enumeration, :class => 'IssuePriority' do
    name 'TestPriority'
  end

  factory :issue do
    sequence(:subject) { |n| "Test issue ##{n}" }
    estimated_hours 4

    project
    tracker { project.trackers.first }
    status { IssueStatus.default || FactoryGirl.create(:issue_status, :default) }
    priority { IssuePriority.invalidate_cache; IssuePriority.default || FactoryGirl.create(:issue_priority, :default) }
    association :author, :factory => :user, :firstname => "Author"
    association :assigned_to, :factory => :user, :firstname => "Assignee"

    trait :reccuring do
      easy_is_repeating true
      easy_repeat_settings Hash[ 'period' => 'daily', 'daily_option' => 'each', 'daily_each_x' => '1', 'endtype' => 'endless', 'create_now' => 'none' ]
    end

    trait :reccuring_monthly do
      easy_is_repeating true
      easy_repeat_settings Hash[ 'period' => 'monthly', 'monthly_option' => 'xth', 'monthly_period' => '1', 'monthly_day' => Date.today.mday+3, 'endtype' => 'endless', 'create_now' => 'none' ]
    end
  end

  factory :time_entry_activity, :parent => :enumeration, :class => 'TimeEntryActivity' do
    name 'TestActivity'
    initialize_with { TimeEntryActivity.find_or_create_by_name(name)}
    factory :default_time_entry_activity, :traits => [:default]
  end

  factory :time_entry do
    hours 1
    spent_on { Date.today - 1.month }

    issue
    project { issue.project }
    user
    association :activity, :factory => :default_time_entry_activity
  end

end
