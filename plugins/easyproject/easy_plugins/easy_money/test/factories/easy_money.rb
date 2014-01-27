FactoryGirl.define do

  factory :easy_money_base_model do
    ignore do
      entity_type = :project
    end

    name 'Nejakej naklad'
    sequence(:price1, 1000) {|n| n * Random.rand(200) }
    sequence(:price2, 1000) {|n| n * Random.rand(200) }
    vat 20
    sequence(:spent_on) {|n| Date.today - n }

    association :entity, factory: :project
  end

  factory :easy_money_expected_expense, :parent => :easy_money_base_model, :class => 'EasyMoneyExpectedExpense' do

  end

end
