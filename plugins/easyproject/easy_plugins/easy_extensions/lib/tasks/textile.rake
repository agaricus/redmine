namespace :easyproject do
  namespace :textile do

    desc <<-END_DESC
    Example:
      bundle exec rake easyproject:textile:migrate_all source_formatting=textile RAILS_ENV=production --trace
    END_DESC
    task :migrate_all => :environment do
      source_formatting = ENV['source_formatting'] || 'textile'

      puts 'This operation is safe - all data is saved before migrating.'
      puts 'This operation could take a while, please wait ...'

      EasyTextileMigrator.migrate_all_entities_to_html(source_formatting)

      puts 'Done.'
    end

    desc <<-END_DESC
    Example:
      bundle exec rake easyproject:textile:unmigrate_all RAILS_ENV=production --trace
    END_DESC
    task :unmigrate_all => :environment do
      puts 'Restoring data from backup.'
      puts 'This operation could take a while, please wait ...'

      EasyTextileMigrator.unmigrate_all_entities

      puts 'Done.'
    end

    desc <<-END_DESC
    Example:
      bundle exec rake easyproject:textile:migrate_entity RAILS_ENV=production --trace
    END_DESC
    task :migrate_entity => :environment do
      print 'Please enter entity name (Issue, Project, Message, News, ...): '
      entity_name = STDIN.gets.chomp!

      unless EasyTextileMigrator.all_entities[entity_name]
        puts 'Unknown entity.'
        exit
      end

      print "Please enter #{entity_name} ID: "
      entity_id = STDIN.gets.chomp!

      entity = entity_name.constantize.where(:id => entity_id).first

      unless entity
        puts 'Unknown entity.'
        exit
      end

      if EasyTextileMigrator.all_entities[entity_name].size > 1
        print "Please enter #{entity_name} column to migrate (#{EasyTextileMigrator.all_entities[entity_name].collect(&:to_s).join(', ')}): "
        entity_column = STDIN.gets.chomp!

        unless EasyTextileMigrator.all_entities[entity_name].include?(entity_column)
          puts 'Unknown oolumn.'
          exit
        end
      else
        entity_column = EasyTextileMigrator.all_entities[entity_name].first
      end

      EasyTextileMigrator.migrate_entity_column_to_html(entity, entity_column, 'textile')

      puts 'Done.'
    end

    desc <<-END_DESC
    Example:
      bundle exec rake easyproject:textile:unmigrate_entity RAILS_ENV=production --trace
    END_DESC
    task :unmigrate_entity => :environment do
      print 'Please enter entity name (Issue, Project, Message, News, ...): '
      entity_name = STDIN.gets.chomp!

      unless EasyTextileMigrator.all_entities[entity_name]
        puts 'Unknown entity.'
        exit
      end

      print "Please enter #{entity_name} ID: "
      entity_id = STDIN.gets.chomp!

      entity = entity_name.constantize.where(:id => entity_id).first

      unless entity
        puts 'Unknown entity.'
        exit
      end

      if EasyTextileMigrator.all_entities[entity_name].size > 1
        print "Please enter #{entity_name} column to migrate (#{EasyTextileMigrator.all_entities[entity_name].collect(&:to_s).join(', ')}): "
        entity_column = STDIN.gets.chomp!

        unless EasyTextileMigrator.all_entities[entity_name].include?(entity_column)
          puts 'Unknown oolumn.'
          exit
        end
      else
        entity_column = EasyTextileMigrator.all_entities[entity_name].first
      end

      etm = EasyTextileMigrator.where(:entity_type => entity_name, :entity_id => entity_id, :entity_column => entity_column, :source_formatting => 'textile').first

      if etm.nil?
        puts 'Entity cannot be unmigrated, because it wasn\'t be migrated before.'
        exit
      else
        etm.unmigrate_entity_column
      end

      puts 'Done.'
    end

  end
end