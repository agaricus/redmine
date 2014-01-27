namespace :easyproject do
  namespace :easy_money do

    desc <<-END_DESC
    Recalculates time entry expenses on project

    Example:
      bundle exec rake easyproject:easy_money:recalculate_time_entry_expenses_on_project RAILS_ENV=production
    END_DESC

    task :recalculate_time_entry_expenses_on_project => :environment do
      puts ''

      print 'Enter project ID to recalculate (if no ID will be specified than all projects will be recalculated): '

      project_id = STDIN.gets.to_s.strip
      project = nil
      recalculate_subprojects = false

      if project_id.blank?
        print 'Are you sure to recalculate all projects? [y/n]'
        exit unless STDIN.gets.match(/^y$/i)
      else
        project = Project.where(:id => project_id).first
        if project.nil?
          print 'Project not found.'
          exit
        end

        if project.self_and_descendants.has_module(:easy_money).size > 0
          print "Do you want to recalculate subprojects of ##{project.id} - #{project.name}? [y/n]"
          recalculate_subprojects = !STDIN.gets.match(/^y$/i).nil?
        else
          print 'This project or subproject has not enabled Easy Money module.'
          exit
        end
      end

      puts ''

      if project_id.blank?
        project_ids = Project.non_templates.active.has_module(:easy_money).pluck(:id)
      else
        if recalculate_subprojects
          project_ids = project.self_and_descendants.active.has_module(:easy_money).pluck(:id)
        else
          project_ids = [project_id.to_i]
        end
      end

      puts 'Recalculating started ...'

      i = 0
      project_ids.each do |pid|
        i += 1
        p = Project.where(:id => pid).select([:id, :name]).first
        puts "#{i}/#{project_ids.size} recalculating ##{p.id} - #{p.name}"
        EasyMoneyTimeEntryExpense.update_project_time_entry_expenses(pid)
      end

      puts 'Recalculating finished.'
    end

  end
end
