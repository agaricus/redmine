require File.dirname(__FILE__) + '/../easy_extensions/easy_extensions'

namespace :easyproject do
  namespace :validate_langfiles do

    plugins_path = File.join(Rails.root, EasyExtensions::RELATIVE_EASYPROJECT_EASY_PLUGINS_PATH)

    desc <<-END_DESC
    Find duplicity in all availible langfiles.

    Available options:
      * languages => cs|en|sk

    Example:
      bundle exec rake easyproject:validate_langfiles:find_duplicity
      bundle exec rake easyproject:validate_langfiles:find_duplicity language=languages
    END_DESC

    task :find_duplicity => :environment do
      options = {}
      options[:language] = ENV['language'] ? ENV['language'].to_s : 'cs'

      log_file = File.new('langfiles-duplicity.log',  'w+')
      find_duplicity(plugins_path, log_file, options[:language])
      log_file.close
    end

    desc <<-END_DESC
    Find missing keys in all languages versions of EP langfiles.

    Available options:
      * plugin => plugin_name

    Example:
      bundle exec rake easyproject:validate_langfiles:find_missing_keys
      bundle exec rake easyproject:validate_langfiles:find_missing_keys plugin=plugin_name
    END_DESC

    task :find_missing_keys => :environment do
      options = {}
      options[:plugin] = ENV['plugin'].to_s if ENV['plugin']

      log_file = File.new('langfiles-missing_keys.log', 'w+')
      if options[:plugin]
        find_missing_keys(File.join(plugins_path, options[:plugin]), log_file)
      else
        Dir.new(plugins_path).each do |plugin|
          find_missing_keys(File.join(plugins_path, plugin.to_s), log_file) if File.directory?(File.join(plugins_path, plugin, 'config', 'locales'))
        end
      end
      log_file.close    
    end

    def find_duplicity(plugins_path, log_file, language)
      yml_akeys = []      
      Dir.new(plugins_path).each do |plugin|
        yml_file = File.join(plugins_path, plugin.to_s,'config', 'locales', language+'.yml' )
        if File.file?(yml_file)
          log_file.write("Testing plugin: #{plugin.to_s} (#{language}.yml)\n")
          yml_hkeys = YAML.load_file(yml_file)
          yml_akeys = yml_akeys + yml_hkeys[yml_hkeys.keys.first].nested_keys          
        end
      end

      unless yml_akeys.blank?
        if(yml_akeys.size == yml_akeys.uniq.size)
          log_file.write("Info: Non-duplicate keys found!\n")
        else
          log_file.write("Warning: Duplicate keys found!\n")
          log_file.write("[#{(yml_akeys.group_by{|x| x}.collect{|x,y| x if y.size>1}.compact).join("\n")}]\n")
        end
      end
      
    end

    def find_missing_keys(plugin, log_file)
      yml_path = File.join(plugin, 'config', 'locales')
      if File.directory?(yml_path)
        log_file.write("Testing plugin: #{plugin.to_s}\n")        
        yml_files = Dir.new(yml_path).select{|f| !File.directory?(f)}
        yml_files = yml_files & ["cs.yml", "en.yml", "sk.yml"]
        if yml_files.size == 1
          log_file.write("Warning: Plugin cointain only one langfile(#{yml_files.first.to_s})!\n")
          log_file.write("\n")
          return
        end
        if yml_files.include?("cs.yml")
          yml_file1 = 'cs.yml'
        else
          yml_file1 = yml_files.first
        end
        yml_hkeys1 = YAML.load_file(File.join(yml_path,yml_file1))
        yml_akeys1 = yml_hkeys1[yml_hkeys1.keys.first].nested_keys        
        yml_files.each do |yml_file2|
          next if yml_file2 == yml_file1

          yml_hkeys2 = YAML.load_file(File.join(yml_path,yml_file2))
          yml_akeys2 = yml_hkeys2[yml_hkeys2.keys.first].nested_keys
          log_file.write("\n\nTesting langfiles: #{yml_file1.to_s} & #{yml_file2.to_s}\nMissing keys in #{yml_file2.to_s}:\n")
          log_file.write('-'*80+"\n")
          if (yml_akeys1-yml_akeys2).blank?
            log_file.write("Info: All keys have been found!\n")
          else
            log_file.write("[#{(yml_akeys1-yml_akeys2).join("\n")}]\n")
          end
          log_file.write("\n\nTesting langfiles: #{yml_file2.to_s} & #{yml_file1.to_s}\nMissing keys in #{yml_file1.to_s}:\n")
          log_file.write('-'*80+"\n")
          if (yml_akeys2-yml_akeys1).blank?
            log_file.write("Info: All keys have been found!\n")
          else
            log_file.write("[#{(yml_akeys2-yml_akeys1).join("\n")}]\n")
          end
        end        
      end
      log_file.write("\n")
    end

  end
end