namespace :easyproject do
  namespace :copy do

    desc <<-END_DESC
    Copy project with ID and X times.

    Example:
      bundle exec rake easyproject:copy:project project_id=ID copies=X RAILS_ENV=production
    END_DESC

#    console:
#    User.current = User.find(:first, :conditions => {:admin => true})
#    projects_to_copy = Project.find(2415).descendants
#    projects_dest = Project.all.select{|p| p.root? == true && p.descendants.empty? == true && p.descendants.empty? == true && p.easy_is_easy_template? == false && p.status == 1} - [Project.find(56),Project.find(1746),Project.find(3502)]
#    projects_dest.each do |project|
#      projects_to_copy.each do |project_to_copy|
#        pp "copy #{project_to_copy.name}(#{project_to_copy.id.to_s}) into #{project.name}(#{project.id.to_s})"
#        project_to_copy.project_with_subprojects_from_template(project.id, {project_to_copy.id.to_s => {:name => project_to_copy.name}})
#      end
#    end

    task :project => :environment do
      project = Project.find_by_id(ENV['project_id']) if ENV['project_id']
      copies = ENV['copies'].to_i if ENV['copies']
      user = User.where(:admin => true).first

      fail 'Error: No user found with admin privilegies' unless user

      User.current = user

      if project
        name = project.name + ' copy - '
        if copies && copies.is_a?(Integer)
          copies.times do |copy|
            projects_attributes = project.descendants.inject({}){|m, x| m[x.id.to_s] = {:name => x.name}; m}
            projects_attributes[project.id.to_s] = {:name => name + (copy+1).to_s }
            project.project_with_subprojects_from_template('', projects_attributes)
          end
        else
          fail 'Error: Type number of copies!'
        end
      else
        fail 'Error: No project founded to copy!'
      end
    end
  end
end