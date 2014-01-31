FactoryGirl.define do
  factory :easy_sprint do
    sequence(:name) { |n| "Sprint #{n}" }
    start_date { Date.today + Random.rand(40).days }
    due_date { start_date + 4 + Random.rand(10).days }

    association :project
  end
end
