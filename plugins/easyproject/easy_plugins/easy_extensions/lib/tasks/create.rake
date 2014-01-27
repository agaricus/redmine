namespace :easyproject do
  namespace :create do

    desc <<-END_DESC
    Create member to all projects

    Example:
      bundle exec rake easyproject:create:member user_id=51 role_id=8 RAILS_ENV=production
      bundle exec rake easyproject:create:member user_id=51 role_id=8 include_templates=true RAILS_ENV=production
    END_DESC

    task :member => :environment do
      user = User.find_by_id(ENV['user_id']) if ENV['user_id']
      role = Role.find_by_id(ENV['role_id']) if ENV['role_id']
      include_templates = (ENV['include_templates'] == 'true') || false

      fail 'Error: User not found!' unless user
      fail 'Chyba: Role not found!' unless role

      projects = include_templates ? Project.all : Project.non_templates

      projects.each do |p|
        Member.create(:user_id => user.id, :project_id => p.id, :role_ids => [role.id])
      end
    end

  end
end