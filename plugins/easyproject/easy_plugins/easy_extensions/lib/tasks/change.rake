namespace :easyproject do
  namespace :change do

    desc <<-END_DESC
    Reorder subprojects on project or all projects

    Example:
      bundle exec rake easyproject:change:reorder_subprojects RAILS_ENV=production
      bundle exec rake easyproject:change:reorder_subprojects parent_id=35 RAILS_ENV=production
    END_DESC

    task :reorder_subprojects => :environment do
      parent_project = Project.find_by_id(ENV['parent_id']) if ENV['parent_id']

      if parent_project
        parent_project.reorder_subprojects!
      else
        Project.where(:parent_id => nil).all.each do |p|
          p.reorder_subprojects!
        end
      end

    end

    desc <<-END_DESC
    Reorder all root projects

    Example:
      bundle exec rake easyproject:change:reorder_projects RAILS_ENV=production
    END_DESC

    task :reorder_projects => :environment do
      Project.where(:parent_id => nil).all.each do |p|
        begin
          p.set_parent!(nil)
        rescue ActiveRecord::ActiveRecordError => error
          puts "Project: #{p.id} - #{p.name}"
          raise error
        end
      end
    end

  end
end