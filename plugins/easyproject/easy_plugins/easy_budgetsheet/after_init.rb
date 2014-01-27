Dir[File.dirname(__FILE__) + '/lib/easy_budgetsheet/redmine/models/*.rb'].each {|file| require_dependency file }
Dir[File.dirname(__FILE__) + '/lib/easy_budgetsheet/easy_extensions/models/*.rb'].each {|file| require_dependency file }
Dir[File.dirname(__FILE__) + '/lib/easy_budgetsheet/easy_extensions/helpers/*.rb'].each {|file| require_dependency file }

ActionDispatch::Reloader.to_prepare do

  Redmine::AccessControl.map do |map|
    map.project_module :easy_budgetsheet do |pmap|
      pmap.permission :view_budgetsheet, {:budgetsheet => [:index]}, :read => true, :global => true
    end
  end

  Redmine::MenuManager.map :top_menu do |menu|
    menu.push :easy_budgetsheet, {:controller => 'budgetsheet', :action => 'index', :set_filter => '0'}, :caption => :budgetsheet_top_menu, :if => Proc.new{!User.current.in_mobile_view? && User.current.allowed_to?(:view_budgetsheet, nil, :global => true)}, :after => :bulk_time_entry
  end

  require_dependency 'easy_budgetsheet/hooks'

end

EasyQuery.map do |query|
  query.register EasyBudgetSheetQuery
end
