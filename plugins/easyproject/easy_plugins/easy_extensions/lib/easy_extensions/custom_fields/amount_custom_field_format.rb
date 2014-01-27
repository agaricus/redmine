module EasyExtensions
  module CustomFields

    class AmountCustomFieldFormat < Redmine::CustomFieldFormat
      include ActionView::Helpers::NumberHelper
    
      def initialize(options={})
        super('amount', options)
      end

      def format_as_amount(value)
        value = value.to_s
        return "" if value.empty?
        number_to_currency(value)
      end
    end

  end
end