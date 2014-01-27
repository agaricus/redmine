module EasyPatch
  module NumberHelperPatch

    def self.included(base)
      base.extend(ClassMethods)
      base.send(:include, InstanceMethods)

      base.class_eval do

        alias_method_chain :number_to_currency, :easy_extensions

        class << self
        end
      end
    end

    module InstanceMethods

      def number_to_currency_with_easy_extensions(number, options = {})
        options.symbolize_keys!

        defaults  = I18n.translate(:'number.format', :locale => options[:locale], :raise => true) rescue {}
        currency  = I18n.translate(:'number.currency.format', :locale => options[:locale], :raise => true) rescue {}
        defaults  = defaults.merge(currency)

        unit      = options[:unit]      || defaults[:unit]

        if number.is_a?(String) && number.include?(unit)
          number = number.upcase.gsub(unit.upcase, '').gsub(' ', '')
        end

        number_to_currency_without_easy_extensions(number, options)
      end
    end

    module ClassMethods
    end
  end
end
EasyExtensions::PatchManager.register_other_patch 'ActionView::Helpers::NumberHelper', 'EasyPatch::NumberHelperPatch'
