# encoding: utf-8

module EasyMoney
  module ApplicationHelperPatch

    def self.included(base)
      base.send(:include, InstanceMethods)

      base.class_eval do

        def format_easy_money_price(price, project, options={})
          currency = EasyMoneySettings.find_settings_by_name('currency', project).to_s
          currency_format = EasyMoneySettings.find_settings_by_name('currency_format', project)
          currency_format = l('number.currency.format.format') if currency_format.blank?

          precision = options.delete(:precision)
          precision ||= 2 if EasyMoneySettings.find_settings_by_name('round_on_list', project) == '0' && options.delete(:round)
          precision ||= 0

          if options[:no_html]
            number_to_currency(price, :precision => precision, :unit => currency, :delimiter => ' ', :format => currency_format)
          else
            format_number(price, number_to_currency(price, :precision => precision, :unit => currency, :delimiter => ' ', :format => currency_format))
          end
        end

        def link_to_project_with_easy_money(project, options = {})
          {:controller => 'easy_money', :action => 'project_index', :project_id => project}
        end

      end
    end

    module InstanceMethods
    end
  end
end
EasyExtensions::PatchManager.register_helper_patch 'ApplicationHelper', 'EasyMoney::ApplicationHelperPatch'
