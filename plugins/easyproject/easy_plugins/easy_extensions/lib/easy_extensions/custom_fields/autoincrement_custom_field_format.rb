module EasyExtensions
  module CustomFields

    class AutoincrementCustomFieldFormat < Redmine::CustomFieldFormat
      include ActionView::Helpers::NumberHelper
    
      def initialize(options={})
        super('autoincrement', options)
      end

      def format_as_autoincrement(value)
        value = value.to_s
        return "" if value.empty?
        value
      end
    end

  end
end