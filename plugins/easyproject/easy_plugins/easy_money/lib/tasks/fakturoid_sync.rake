namespace :easyproject do
  namespace :easy_money do
    
    desc <<-END_DESC
    Imports new revenues and updates existing ones.

    Example:
      bundle exec rake easyproject:easy_money:update_from_fakturoid subdomain='easysoftware' password='secret' entity_type='Project' entity_id='35' RAILS_ENV=production
    END_DESC
    
    task :update_from_fakturoid => :environment do
      require 'easy_money/easy_sync/easy_sync_money'
      syncmaster = EasySyncMoney.new(EasyMoneyFakturoidSyncRakeHelper::parse_options)
      syncmaster.sync
    end
    
    desc <<-END_DESC
    Imports new revenues.

    Example:
      bundle exec rake easyproject:easy_money:import_from_fakturoid subdomain='easysoftware' password='secret' entity_type='Project' entity_id='35' RAILS_ENV=production
    END_DESC
    
    task :import_from_fakturoid => :environment do
      require 'easy_money/easy_sync/easy_sync_money'
      syncmaster = EasySyncMoney.new(EasyMoneyFakturoidSyncRakeHelper::parse_options)
      syncmaster.sync(true)
    end

    module EasyMoneyFakturoidSyncRakeHelper
      def self.parse_options
        options = {}
        options[:subdomain] = ENV['subdomain'].to_s
        options[:auth] = {:username => ENV['username'] ? ENV['username'].to_s : "X", :password => ENV['password'].to_s}
        options[:entity_type] = ENV['entity_type'].to_s
        options[:entity_id] = ENV['entity_id'].to_i
        options
      end
    end
    
  end
end