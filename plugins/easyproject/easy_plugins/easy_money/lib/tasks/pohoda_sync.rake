namespace :easyproject do
  namespace :easy_money do
        
    desc <<-END_DESC
    Imports new revenues.

    Example:
      bundle exec rake easyproject:easy_money:import_from_pohoda dsn='pohoda_mdb' project_id='1126' RAILS_ENV=production
    END_DESC
    
    task :import_from_pohoda => :environment do
      options = PohodaSyncRakeHelper::parse_options
      
      require 'easy_money/easy_sync/easy_sync_pohoda_revenues'
      syncmaster = EasySyncPohodaRevenues.new(options)
      syncmaster.sync(true)
      
      require 'easy_money/easy_sync/easy_sync_pohoda_expenses'
      syncmaster = EasySyncPohodaExpenses.new(options)
      syncmaster.sync(true)
    end
    
    module PohodaSyncRakeHelper
      def self.parse_options
        options = {}
        options[:dsn] = ENV['dsn'].to_s
        options[:entity_id] = ENV['project_id'].to_i
        options
      end
    end
    
  end
end