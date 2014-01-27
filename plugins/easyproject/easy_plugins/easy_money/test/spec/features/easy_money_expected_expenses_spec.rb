
feature 'Easy money expected expenses' do
  
  before :each do
    logged_user( FactoryGirl.create(:admin_user) )
  end

  context 'with some valid expenses' do  

    before :each do
      FactoryGirl.create_list(:easy_money_expected_expense, 10)
    end

    scenario 'user checks the sum and it should be in right currency', :js => true do
      currency = EasyMoneySettings.find_by_name('currency')
      currency ||= EasyMoneySettings.new(:name => 'currency')
      currency.value = 'fufnik'
      currency.save

      visit url_for({:controller => 'easy_money_expected_expenses', :action => 'index', :set_filter => '0', :only_path => true })

      find('#totalsum-summary .price1').text.should match(/fufnik/)

    end
  end

end