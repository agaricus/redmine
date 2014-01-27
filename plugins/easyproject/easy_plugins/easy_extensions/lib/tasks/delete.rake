namespace :easyproject do
  namespace :delete do

    desc <<-END_DESC
    Delete time_entry with 0hours.

    Example:
      bundle exec rake easyproject:delete:time_entry RAILS_ENV=production
    END_DESC

    task :time_entry => :environment do
      TimeEntry.where(:hours => 0).each do |time_entry|
        time_entry.destroy
      end
    end

    desc <<-END_DESC
    Delete member from all projects

    Example:
      bundle exec rake easyproject:delete:member user_id=51 RAILS_ENV=production
      bundle exec rake easyproject:delete:member user_id=51 include_templates=true RAILS_ENV=production
    END_DESC

    task :member => :environment do
      user = User.find_by_id(ENV['user_id']) if ENV['user_id']
      include_templates = (ENV['include_templates'] == 'true') || false

      fail 'Error: User not found!' unless user

      scope = Member.where(["#{Member.table_name}.user_id = ?", user.id])
      scope = scope.where(["#{Project.table_name}.easy_is_easy_template = ?", false]) unless include_templates
      scope.scoped(:include => [:project]).all.each(&:destroy)
    end

  end
end