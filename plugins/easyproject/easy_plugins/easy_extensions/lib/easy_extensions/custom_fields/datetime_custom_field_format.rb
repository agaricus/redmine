module EasyExtensions
  module CustomFields

    class DateTimeCustomFieldFormat < Redmine::CustomFieldFormat

      def initialize(options={})
        super('datetime', options)
      end

      def format_as_datetime(value)
        begin; format_time(value.to_time(:local)); rescue; value; end
      end
    end

  end
end