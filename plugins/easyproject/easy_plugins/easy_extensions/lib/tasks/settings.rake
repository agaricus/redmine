namespace :easyproject do
  namespace :settings do

    desc <<-END_DESC
    Set new app title.

    Example:
      bundle exec rake easyproject:settings:set_app_title app_title="new app title"
    END_DESC

    task :set_app_title => :environment do
      if setting = (Setting.where(:name => 'app_title').first || Setting.new(:name => 'app_title'))
        setting.value = ENV['app_title'].to_s
        setting.save
        if setting.errors.size > 0
          fail 'Error: ' + setting.errors.full_messages.join('; ')
        end
      end

      if setting = (Setting.where(:name => 'host_name').first || Setting.new(:name => 'host_name'))
        setting.value = ENV['fqdn'].to_s
        setting.save
        if setting.errors.size > 0
          fail 'Error: ' + setting.errors.full_messages.join('; ')
        end
      end
    end

    desc <<-END_DESC
    Set app settings

    Example:
      bundle exec rake easyproject:settings:set_app_settings app_title="new app title"
    END_DESC

    task :set_app_settings => :environment do
      ENV.each do |k, v|
        if s = Setting.where(:name => k).first
          s.value = v.to_s.strip
          s.save
          if s.errors.size > 0
            fail "Error: (#{k}) " + s.errors.full_messages.join('; ')
          end
        end
      end
    end

  end
end