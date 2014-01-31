Dir[File.dirname(__FILE__) + '/lib/easy_agile_board/redmine/controllers/*.rb'].each {|file| require_dependency file }
Dir[File.dirname(__FILE__) + '/lib/easy_agile_board/redmine/helpers/*.rb'].each {|file| require_dependency file }
Dir[File.dirname(__FILE__) + '/lib/easy_agile_board/redmine/models/*.rb'].each {|file| require_dependency file }
Dir[File.dirname(__FILE__) + '/lib/easy_agile_board/redmine/others/*.rb'].each {|file| require_dependency file }

ActionDispatch::Reloader.to_prepare do

  require 'easy_agile_board/hooks'

  Redmine::AccessControl.map do |map|
    map.permission :view_easy_agile_board, {:easy_agile_board => [:show], :easy_sprints => [:show, :index]}, :read => true
    map.permission :edit_easy_agile_board, {:easy_agile_board => [:show], :easy_sprints => [:new, :create, :show, :index, :edit, :update, :destroy, :assign_issue, :unassign_issue]}
  end

end

EasyQuery.map do |query|
  query.register EasyAgileBoardQuery
end
