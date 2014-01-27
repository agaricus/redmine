class EasyMoneyMailer < EasyMailer

  def easy_money_expected_expense_added(easy_money)
    redmine_headers 'Project' => easy_money.project.identifier
    @author = User.current
    @easy_money = easy_money
    @easy_money_url = url_for(:controller => 'easy_money_expected_expenses', :action => 'edit', :id => easy_money)

    mail :to => easy_money.recipients, :subject => "[#{easy_money.entity_title}] #{l(:label_easy_money_expected_expense_added)}: #{easy_money.name}"
  end

  def easy_money_expected_expense_updated(easy_money)
    redmine_headers 'Project' => easy_money.project.identifier
    @author = User.current
    @easy_money = easy_money
    @easy_money_url = url_for(:controller => 'easy_money_expected_expenses', :action => 'edit', :id => easy_money)

    mail :to => easy_money.recipients, :subject => "[#{easy_money.entity_title}] #{l(:label_easy_money_expected_expense_updated)}: #{easy_money.name}"
  end

  def easy_money_expected_revenue_added(easy_money)
    redmine_headers 'Project' => easy_money.project.identifier
    @author = User.current
    @easy_money = easy_money
    @easy_money_url = url_for(:controller => 'easy_money_expected_revenues', :action => 'edit', :id => easy_money)

    mail :to => easy_money.recipients, :subject => "[#{easy_money.entity_title}] #{l(:label_easy_money_expected_revenue_added)}: #{easy_money.name}"
  end

  def easy_money_expected_revenue_updated(easy_money)
    redmine_headers 'Project' => easy_money.project.identifier
    @author = User.current
    @easy_money = easy_money
    @easy_money_url = url_for(:controller => 'easy_money_expected_revenues', :action => 'edit', :id => easy_money)

    mail :to => easy_money.recipients, :subject => "[#{easy_money.entity_title}] #{l(:label_easy_money_expected_revenue_updated)}: #{easy_money.name}"
  end

  def easy_money_other_expense_added(easy_money)
    redmine_headers 'Project' => easy_money.project.identifier
    @author = User.current
    @easy_money = easy_money
    @easy_money_url = url_for(:controller => 'easy_money_other_expenses', :action => 'edit', :id => easy_money)

    mail :to => easy_money.recipients, :subject => "[#{easy_money.entity_title}] #{l(:label_easy_money_other_expense_added)}: #{easy_money.name}"
  end

  def easy_money_other_expense_updated(easy_money)
    redmine_headers 'Project' => easy_money.project.identifier
    @author = User.current
    @easy_money = easy_money
    @easy_money_url = url_for(:controller => 'easy_money_other_expenses', :action => 'edit', :id => easy_money)

    mail :to => easy_money.recipients, :subject => "[#{easy_money.entity_title}] #{l(:label_easy_money_other_expense_updated)}: #{easy_money.name}"
  end

  def easy_money_other_revenue_added(easy_money)
    redmine_headers 'Project' => easy_money.project.identifier
    @author = User.current
    @easy_money = easy_money
    @easy_money_url = url_for(:controller => 'easy_money_other_revenues', :action => 'edit', :id => easy_money)

    mail :to => easy_money.recipients, :subject => "[#{easy_money.entity_title}] #{l(:label_easy_money_other_revenue_added)}: #{easy_money.name}"
  end

  def easy_money_other_revenue_updated(easy_money)
    redmine_headers 'Project' => easy_money.project.identifier
    @author = User.current
    @easy_money = easy_money
    @easy_money_url = url_for(:controller => 'easy_money_other_revenues', :action => 'edit', :id => easy_money)

    mail :to => easy_money.recipients, :subject => "[#{easy_money.entity_title}] #{l(:label_easy_money_other_revenue_updated)}: #{easy_money.name}"
  end

end
