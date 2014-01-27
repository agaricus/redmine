FactoryGirl.define do
  factory :user do
    firstname 'John'
    sequence(:lastname) {|n| 'Doe' + n.to_s }
    login { "#{firstname}-#{lastname}".downcase }
    sequence(:mail) {|n| "user#{n}@test.com" }
    admin false
    language 'en'
    status 1
    mail_notification 'only_my_events'

    trait :admin do
      firstname 'Admin'
      admin true
    end

    factory :admin_user, :traits => [:admin]
  end

end
